//
//  ReaderViewModel.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import OSLog
import Photos
import SDWebImage
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum ReadingDirection: CaseIterable, Hashable {
  case ltr
  case rtl
  case vertical
  case webtoon

  static func fromString(_ direction: String) -> ReadingDirection {
    switch direction.uppercased() {
    case "LEFT_TO_RIGHT":
      return .ltr
    case "RIGHT_TO_LEFT":
      return .rtl
    case "VERTICAL":
      return .vertical
    case "WEBTOON":
      return .webtoon
    default:
      return .ltr
    }
  }

  var displayName: String {
    switch self {
    case .ltr:
      return "LTR"
    case .rtl:
      return "RTL"
    case .vertical:
      return "Vertical"
    case .webtoon:
      return "Webtoon"
    }
  }

  var icon: String {
    if #available(iOS 18.0, *) {
      switch self {
      case .ltr:
        return "inset.filled.trailinghalf.arrow.trailing.rectangle"
      case .rtl:
        return "inset.filled.leadinghalf.arrow.leading.rectangle"
      case .vertical:
        return "rectangle.portrait.bottomhalf.filled"
      case .webtoon:
        return "arrow.up.and.down.square"
      }
    } else {
      switch self {
      case .ltr:
        return "rectangle.trailinghalf.inset.filled.arrow.trailing"
      case .rtl:
        return "rectangle.leadinghalf.inset.filled.arrow.leading"
      case .vertical:
        return "rectangle.portrait.bottomhalf.filled"
      case .webtoon:
        return "arrow.up.and.down.square"
      }
    }
  }
}

@MainActor
@Observable
class ReaderViewModel {
  var pages: [BookPage] = []
  var currentPage = 0
  var isLoading = true
  var errorMessage: String?
  var pageImageCache: ImageCache
  var readingDirection: ReadingDirection = .ltr

  private let bookService = BookService.shared
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Komga", category: "ReaderViewModel")
  /// Current book ID for API calls and cache access
  var bookId: String = ""

  /// Track ongoing download tasks to prevent duplicate downloads for the same page
  private var downloadingTasks: [Int: Task<URL?, Never>] = [:]

  init() {
    self.pageImageCache = ImageCache()
  }

  func loadPages(bookId: String, initialPage: Int? = nil) async {
    self.bookId = bookId
    isLoading = true
    errorMessage = nil

    // Cancel all ongoing download tasks when loading a new book
    for (_, task) in downloadingTasks {
      task.cancel()
    }
    downloadingTasks.removeAll()

    do {
      pages = try await bookService.getBookPages(id: bookId)

      // Set initial page if provided
      // Note: API page numbers are 1-based, but array indices are 0-based
      if let initialPage = initialPage {
        if let pageIndex = pages.firstIndex(where: { $0.number == initialPage }) {
          currentPage = pageIndex
        }
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  /// Get page image file URL from disk cache, or download and cache if not available
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Local file URL if available, nil if download failed
  /// - Note: Prevents duplicate downloads by tracking ongoing tasks
  func getPageImageFileURL(pageIndex: Int) async -> URL? {
    guard pageIndex >= 0 && pageIndex < pages.count else {
      logger.warning(
        "⚠️ Invalid page index: \(pageIndex) (total pages: \(self.pages.count)) for book \(self.bookId)"
      )
      return nil
    }

    guard !bookId.isEmpty else {
      logger.warning("⚠️ Book ID is empty, cannot load page image")
      return nil
    }

    // Check if already cached
    if let cachedFileURL = getCachedImageFileURL(pageIndex: pageIndex) {
      logger.debug(
        "✅ Using cached image for page \(self.pages[pageIndex].number) (index: \(pageIndex)) for book \(self.bookId)"
      )
      return cachedFileURL
    }

    // Check if there's already a download task for this page
    if let existingTask = downloadingTasks[pageIndex] {
      logger.debug(
        "⏳ Waiting for existing download task for page \(self.pages[pageIndex].number) (index: \(pageIndex)) for book \(self.bookId)"
      )
      // Wait for the existing task to complete
      if let result = await existingTask.value {
        return result
      }
      // If the existing task returned nil, check cache again
      // (the file might have been saved by another concurrent request)
      if let cachedFileURL = getCachedImageFileURL(pageIndex: pageIndex) {
        return cachedFileURL
      }
      return nil
    }

    // Not cached and no existing task, create a new download task
    let apiPageNumber = pages[pageIndex].number
    let downloadTask = Task<URL?, Never> {
      logger.info(
        "📥 Downloading page \(apiPageNumber) (index: \(pageIndex)) for book \(self.bookId)")

      do {
        let result = try await bookService.getBookPage(bookId: self.bookId, page: apiPageNumber)
        let data = result.data
        let contentType = result.contentType

        let dataSize = ByteCountFormatter.string(
          fromByteCount: Int64(data.count), countStyle: .binary)
        logger.info(
          "✅ Downloaded page \(apiPageNumber) successfully (\(dataSize)) for book \(self.bookId)")

        // Save raw image data to disk cache (decoding is handled by SDWebImage)
        await pageImageCache.storeImageData(
          data, forKey: pageIndex, bookId: self.bookId, contentType: contentType)

        // Return the cached file URL
        if let fileURL = getCachedImageFileURL(pageIndex: pageIndex) {
          logger.debug("💾 Saved page \(apiPageNumber) to disk cache for book \(self.bookId)")
          return fileURL
        } else {
          logger.error(
            "❌ Failed to get file URL after saving page \(apiPageNumber) to cache for book \(self.bookId)"
          )
          return nil
        }
      } catch {
        // Download failed
        logger.error(
          "❌ Failed to download page \(apiPageNumber) (index: \(pageIndex)) for book \(self.bookId): \(error.localizedDescription)"
        )
        return nil
      }
    }

    // Store the task
    downloadingTasks[pageIndex] = downloadTask

    // Wait for the task to complete
    let result = await downloadTask.value

    // Remove the task from the dictionary
    downloadingTasks.removeValue(forKey: pageIndex)

    return result
  }

  /// Get cached image file URL from disk cache
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Local file URL if the cached file exists, nil otherwise
  private func getCachedImageFileURL(pageIndex: Int) -> URL? {
    // Construct the file path: CacheDirectory/KomgaImageCache/{bookId}/page_{index}.data
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let diskCacheURL = cacheDir.appendingPathComponent("KomgaImageCache", isDirectory: true)
    let bookCacheDir = diskCacheURL.appendingPathComponent(bookId, isDirectory: true)
    let fileURL = bookCacheDir.appendingPathComponent("page_\(pageIndex).data")

    // Verify file exists before returning URL
    if FileManager.default.fileExists(atPath: fileURL.path) {
      return fileURL
    }
    return nil
  }

  /// Get cached content type for a page
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Content type string if cached, nil otherwise
  func getCachedContentType(pageIndex: Int) -> String? {
    return pageImageCache.getContentType(forKey: pageIndex, bookId: bookId)
  }

  /// Get page image info (file URL and content type) for saving
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Tuple containing file URL and content type, or nil if not available
  func getPageImageInfo(pageIndex: Int) -> (fileURL: URL, contentType: String)? {
    guard pageIndex >= 0 && pageIndex < pages.count else {
      return nil
    }

    guard !bookId.isEmpty else {
      return nil
    }

    guard let fileURL = getCachedImageFileURL(pageIndex: pageIndex) else {
      return nil
    }

    guard let contentType = getCachedContentType(pageIndex: pageIndex) else {
      return nil
    }

    return (fileURL, contentType)
  }

  /// Parse MIME type from content type string (removes parameters)
  /// - Parameter contentType: Full content type string (e.g., "image/jpeg; charset=utf-8")
  /// - Returns: Clean MIME type string (e.g., "image/jpeg")
  static func parseMimeType(from contentType: String) -> String {
    return contentType.split(separator: ";").first?.trimmingCharacters(in: .whitespaces)
      ?? contentType
  }

  /// Preload pages around the current page for smoother scrolling
  /// Preloads 2 pages before and 4 pages after the current page
  func preloadPages() async {
    let preloadBefore = max(0, currentPage - 2)
    let preloadAfter = min(currentPage + 4, pages.count)
    let pagesToPreload = Array(preloadBefore..<preloadAfter)

    // Load pages concurrently for better performance
    await withTaskGroup(of: Void.self) { group in
      for index in pagesToPreload {
        // Only preload if not already cached
        if !pageImageCache.hasImage(forKey: index, bookId: bookId) {
          group.addTask {
            _ = await self.getPageImageFileURL(pageIndex: index)
          }
        }
      }
    }
  }

  /// Update reading progress on the server
  /// Uses API page number (1-based) instead of array index (0-based)
  func updateProgress() async {
    guard !bookId.isEmpty else { return }
    guard currentPage >= 0 && currentPage < pages.count else { return }

    let completed = currentPage >= pages.count - 1
    let apiPageNumber = pages[currentPage].number

    do {
      try await bookService.updateReadProgress(
        bookId: bookId,
        page: apiPageNumber,
        completed: completed
      )
    } catch {
      // Progress updates are non-critical, fail silently
    }
  }

  /// Convert display index to actual page index based on reading direction
  /// - Parameter displayIndex: The index as displayed to the user
  /// - Returns: The actual page index in the pages array
  func displayIndexToPageIndex(_ displayIndex: Int) -> Int {
    switch readingDirection {
    case .ltr:
      return displayIndex
    case .rtl:
      return pages.count - 1 - displayIndex
    case .vertical, .webtoon:
      return displayIndex
    }
  }

  /// Convert actual page index to display index based on reading direction
  /// - Parameter pageIndex: The actual page index in the pages array
  /// - Returns: The index as displayed to the user
  func pageIndexToDisplayIndex(_ pageIndex: Int) -> Int {
    switch readingDirection {
    case .ltr:
      return pageIndex
    case .rtl:
      return pages.count - 1 - pageIndex
    case .vertical, .webtoon:
      return pageIndex
    }
  }

  /// Save page image to Photos from cache
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Result indicating success or failure with error message
  func savePageImageToPhotos(pageIndex: Int) async -> Result<Void, SaveImageError> {
    // Get page image info
    guard let (imageURL, contentType) = getPageImageInfo(pageIndex: pageIndex) else {
      if pageIndex < 0 || pageIndex >= pages.count {
        return .failure(.invalidPageIndex)
      }
      if bookId.isEmpty {
        return .failure(.bookIdEmpty)
      }
      return .failure(.imageNotCached)
    }

    // Check photo library authorization
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      return .failure(.photoLibraryAccessDenied)
    }

    // Check if format is supported by Photos library using UTType
    // Photos library supports: JPEG, PNG, HEIF, but not WebP
    let mimeType = Self.parseMimeType(from: contentType)
    let utType = UTType(mimeType: mimeType)

    // Check if the UTType conforms to any of the supported image types
    let supportedTypes: [UTType] = [.jpeg, .png, .heic, .heif]
    let isSupported = utType != nil && supportedTypes.contains { utType!.conforms(to: $0) }

    let finalImageData: Data
    let fileExtension: String

    if isSupported, let utType = utType, let ext = utType.preferredFilenameExtension {
      // Format is supported, use original data
      guard let imageData = try? Data(contentsOf: imageURL) else {
        return .failure(.failedToLoadImageData)
      }
      finalImageData = imageData
      fileExtension = ext
    } else {
      // Format is not supported (e.g., WebP), convert to PNG using SDWebImage
      // Load image using SDWebImage which can decode WebP and other formats
      // Note: SDImageCodersManager decoding is lossless, only format conversion
      guard let image = await loadImageWithSDWebImage(from: imageURL) else {
        return .failure(.failedToLoadImageData)
      }

      // Convert UIImage to PNG data (PNG is lossless, no compression)
      // pngData() uses lossless encoding, preserving original quality
      guard let pngData = image.pngData() else {
        return .failure(.failedToLoadImageData)
      }
      finalImageData = pngData
      fileExtension = "png"
    }

    // Create a temporary file with correct extension in a location accessible to Photos
    let tempDir = FileManager.default.temporaryDirectory
    let timestamp = ISO8601DateFormatter().string(from: Date())
      .replacingOccurrences(of: ":", with: "-")
      .replacingOccurrences(of: ".", with: "-")
    let tempFileName = "komga_page_\(pageIndex)_\(timestamp).\(fileExtension)"
    let tempFileURL = tempDir.appendingPathComponent(tempFileName)

    // Write image data to temporary file with correct extension
    do {
      try finalImageData.write(to: tempFileURL)
    } catch {
      return .failure(.saveError("Failed to create temporary file: \(error.localizedDescription)"))
    }

    // Clean up temporary file after saving
    defer {
      try? FileManager.default.removeItem(at: tempFileURL)
    }

    // Save to photo library using temporary file URL with correct extension
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tempFileURL)
      }
      return .success(())
    } catch {
      return .failure(.saveError(error.localizedDescription))
    }
  }

  /// Load image using SDWebImage (supports WebP and other formats)
  /// - Parameter fileURL: Local file URL
  /// - Returns: UIImage if successfully loaded, nil otherwise
  /// - Note: Decoding is lossless, only converts encoded format to bitmap
  private func loadImageWithSDWebImage(from fileURL: URL) async -> UIImage? {
    return await withCheckedContinuation { continuation in
      // Use SDWebImage to load and decode the image
      // SDWebImage can handle WebP and other formats
      // Decoding is lossless - only converts encoded format (WebP, etc.) to bitmap
      SDImageCache.shared.queryImage(
        forKey: fileURL.absoluteString,
        options: [],
        context: nil
      ) { image, data, cacheType in
        if let image = image {
          continuation.resume(returning: image)
        } else {
          // If not in cache, load directly from file
          // SDImageCodersManager decoding is lossless - preserves original image quality
          // Options: nil means use default (lossless) decoding
          if let imageData = try? Data(contentsOf: fileURL),
            let image = SDImageCodersManager.shared.decodedImage(with: imageData, options: nil)
          {
            continuation.resume(returning: image)
          } else {
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }

}

enum SaveImageError: Error, LocalizedError {
  case invalidPageIndex
  case bookIdEmpty
  case imageNotCached
  case photoLibraryAccessDenied
  case failedToLoadImageData
  case unsupportedImageFormat
  case saveError(String)

  var errorDescription: String? {
    switch self {
    case .invalidPageIndex:
      return "Invalid page index"
    case .bookIdEmpty:
      return "Book ID is empty"
    case .imageNotCached:
      return "Image not cached yet"
    case .photoLibraryAccessDenied:
      return "Photo library access denied"
    case .failedToLoadImageData:
      return "Failed to load image data"
    case .unsupportedImageFormat:
      return "Image format not supported. Only JPEG, PNG, and HEIF formats can be saved to Photos."
    case .saveError(let message):
      return message
    }
  }
}
