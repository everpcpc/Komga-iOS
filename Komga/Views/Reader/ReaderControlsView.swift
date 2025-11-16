//
//  ReaderControlsView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI
import UniformTypeIdentifiers

struct ReaderControlsView: View {
  @Binding var showingControls: Bool
  @Binding var showingReadingDirectionPicker: Bool
  let viewModel: ReaderViewModel
  let currentBook: Book?
  let onDismiss: () -> Void

  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  @State private var saveImageResult: SaveImageResult?
  @State private var showSaveAlert = false
  @State private var showDocumentPicker = false
  @State private var fileToSave: URL?

  enum SaveImageResult: Equatable {
    case success
    case failure(String)
  }

  var body: some View {
    VStack {
      // Top bar
      VStack(spacing: 12) {
        HStack {
          Button {
            onDismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.title2)
              .foregroundColor(.white)
              .padding()
              .background(themeColorOption.color.opacity(0.8))
              .clipShape(Circle())
          }
          .frame(minWidth: 40, minHeight: 40)
          .contentShape(Rectangle())

          Spacer()

          // Display mode toggle button
          Button {
            showingReadingDirectionPicker = true
          } label: {
            Image(systemName: viewModel.readingDirection.icon)
              .font(.title3)
              .foregroundColor(.white)
              .padding()
              .background(themeColorOption.color.opacity(0.8))
              .clipShape(Circle())
          }
          .frame(minWidth: 40, minHeight: 40)
          .contentShape(Rectangle())
        }
        .padding(.horizontal)
      }
      .padding(.top)
      .allowsHitTesting(true)

      // Series and book title
      if let book = currentBook {
        VStack(spacing: 4) {
          Text(book.seriesTitle)
            .font(.headline)
            .foregroundColor(.white)
          Text("#\(Int(book.number)) - \(book.metadata.title)")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeColorOption.color.opacity(0.8))
        .cornerRadius(12)
      }

      Spacer()

      // Bottom slider
      VStack(spacing: 12) {
        HStack(spacing: 12) {
          // Save to file button
          Button {
            Task {
              await prepareSaveToFile()
            }
          } label: {
            Image(systemName: "folder.badge.plus")
              .font(.title3)
              .foregroundColor(.white)
              .padding()
              .background(themeColorOption.color.opacity(0.8))
              .clipShape(Circle())
          }
          .frame(minWidth: 40, minHeight: 40)
          .contentShape(Rectangle())

          Spacer()

          // Page count
          Text("\(viewModel.currentPage + 1) / \(viewModel.pages.count)")
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(themeColorOption.color.opacity(0.8))
            .cornerRadius(20)
            .monospacedDigit()

          Spacer()

          // Save to Photos button
          Button {
            Task {
              await saveCurrentPageToPhotos()
            }
          } label: {
            Image(systemName: "photo.badge.arrow.down.fill")
              .font(.title3)
              .foregroundColor(.white)
              .padding()
              .background(themeColorOption.color.opacity(0.8))
              .clipShape(Circle())
          }
          .frame(minWidth: 40, minHeight: 40)
          .contentShape(Rectangle())
        }

        ProgressView(
          value: Double(min(viewModel.currentPage + 1, viewModel.pages.count)),
          total: Double(viewModel.pages.count)
        )
        .scaleEffect(x: viewModel.readingDirection == .rtl ? -1 : 1, y: 1)
      }
      .padding()
    }
    .allowsHitTesting(true)
    .transition(.opacity)
    .alert("Save Image", isPresented: $showSaveAlert) {
      Button("OK") {
        saveImageResult = nil
      }
    } message: {
      if let result = saveImageResult {
        switch result {
        case .success:
          Text("Image saved to Photos successfully")
        case .failure(let error):
          Text("Failed to save image: \(error)")
        }
      }
    }
    .onChange(of: saveImageResult) { oldValue, newValue in
      if newValue != nil {
        showSaveAlert = true
      }
    }
    .fileExporter(
      isPresented: $showDocumentPicker,
      document: fileToSave.map { ImageFileDocument(url: $0) },
      contentType: .item,
      defaultFilename: fileToSave?.lastPathComponent ?? "page"
    ) { result in
      // Clean up temporary file after export
      if let tempURL = fileToSave {
        try? FileManager.default.removeItem(at: tempURL)
      }
      fileToSave = nil
    }
  }

  // Prepare file for saving to Files app
  private func prepareSaveToFile() async {
    // Get page image info
    guard
      let (cachedFileURL, contentType) = viewModel.getPageImageInfo(
        pageIndex: viewModel.currentPage)
    else {
      await MainActor.run {
        saveImageResult = .failure("Image not available")
      }
      return
    }

    let fileExtension = fileExtensionFromContentType(contentType)

    // Create a temporary file with proper extension in a location accessible to document picker
    let tempDir = FileManager.default.temporaryDirectory
    let timestamp = ISO8601DateFormatter().string(from: Date())
      .replacingOccurrences(of: ":", with: "-")
      .replacingOccurrences(of: ".", with: "-")
    let fileName = "page_\(viewModel.currentPage + 1)_\(timestamp).\(fileExtension)"
    let tempFileURL = tempDir.appendingPathComponent(fileName)

    // Copy file to temp location with proper extension
    do {
      if FileManager.default.fileExists(atPath: tempFileURL.path) {
        try FileManager.default.removeItem(at: tempFileURL)
      }
      try FileManager.default.copyItem(at: cachedFileURL, to: tempFileURL)

      await MainActor.run {
        fileToSave = tempFileURL
        showDocumentPicker = true
      }
    } catch {
      await MainActor.run {
        saveImageResult = .failure("Failed to prepare file: \(error.localizedDescription)")
      }
    }
  }

  // Get file extension from content type using UTType
  private func fileExtensionFromContentType(_ contentType: String) -> String {
    let mimeType = ReaderViewModel.parseMimeType(from: contentType)

    // Try to create UTType from MIME type
    if let utType = UTType(mimeType: mimeType) {
      // Get preferred file extension from UTType
      if let preferredExtension = utType.preferredFilenameExtension {
        return preferredExtension
      }
    }

    // Default to png if unknown
    return "png"
  }

  // Save current page image to Photos
  private func saveCurrentPageToPhotos() async {
    let result = await viewModel.savePageImageToPhotos(pageIndex: viewModel.currentPage)

    await MainActor.run {
      switch result {
      case .success:
        saveImageResult = .success
      case .failure(let error):
        saveImageResult = .failure(error.localizedDescription)
      }
    }
  }
}

// File document wrapper for fileExporter
struct ImageFileDocument: FileDocument {
  let url: URL
  let fileType: UTType?

  static var readableContentTypes: [UTType] {
    [.item]
  }

  static var writableContentTypes: [UTType] {
    [.item]
  }

  init(url: URL) {
    self.url = url
    // Detect file type from extension
    self.fileType = UTType(filenameExtension: url.pathExtension)
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents,
      let url = URL(dataRepresentation: data, relativeTo: nil)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.url = url
    self.fileType = UTType(filenameExtension: url.pathExtension)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = try Data(contentsOf: url)
    return FileWrapper(regularFileWithContents: data)
  }
}
