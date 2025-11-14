//
//  HistoryView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct HistoryView: View {
  @State private var bookViewModel = BookViewModel()

  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Library Picker at the top
          HStack {
            Menu {
              Picker(selection: $selectedLibraryId) {
                Label("All Libraries", systemImage: "square.grid.2x2").tag("")
                ForEach(LibraryManager.shared.libraries) { library in
                  Label(library.name, systemImage: "books.vertical").tag(library.id)
                }
              } label: {
                Label(
                  selectedLibrary?.name ?? "All Libraries",
                  systemImage: selectedLibraryId.isEmpty ? "square.grid.2x2" : "books.vertical")
              }
              .pickerStyle(.inline)
            } label: {
              HStack {
                Image(systemName: selectedLibraryId.isEmpty ? "square.grid.2x2" : "books.vertical")
                Text(selectedLibrary?.name ?? "All Libraries")
                  .font(.body)
                Image(systemName: "chevron.down")
                  .font(.caption)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color(.systemGray6))
              .cornerRadius(8)
            }
            Spacer()
            Button {
              Task {
                await bookViewModel.loadRecentlyReadBooks(
                  libraryId: selectedLibraryId, refresh: true)
              }
            } label: {
              Image(systemName: "arrow.clockwise.circle")
                .font(.title2)
                .symbolEffect(.rotate, value: bookViewModel.isLoading)
            }
            .disabled(bookViewModel.isLoading)
          }
          .padding(.horizontal)

          if bookViewModel.isLoading && bookViewModel.books.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding()
              .transition(.opacity)
          } else if let errorMessage = bookViewModel.errorMessage {
            VStack(spacing: 16) {
              Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(themeColorOption.color)
              Text(errorMessage)
                .multilineTextAlignment(.center)
              Button("Retry") {
                Task {
                  await bookViewModel.loadRecentlyReadBooks(
                    libraryId: selectedLibraryId, refresh: true)
                }
              }
            }
            .padding()
            .transition(.opacity)
          } else if !bookViewModel.books.isEmpty {
            // Recently Read Books Section
            ReadHistorySection(
              title: "Recently Read Books",
              books: bookViewModel.books,
              bookViewModel: bookViewModel,
              onLoadMore: {
                Task {
                  await bookViewModel.loadRecentlyReadBooks(
                    libraryId: selectedLibraryId, refresh: false)
                }
              },
              isLoading: bookViewModel.isLoading
            )
            .animation(.default, value: bookViewModel.books)
            .transition(.move(edge: .top).combined(with: .opacity))
          } else {
            VStack(spacing: 16) {
              Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
              Text("No reading history")
                .font(.headline)
              Text("Start reading some books to see your history here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .transition(.opacity)
          }
        }
        .padding(.vertical)
      }
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.inline)
      .animation(.default, value: selectedLibraryId)
      .onChange(of: selectedLibraryId) {
        Task {
          await bookViewModel.loadRecentlyReadBooks(libraryId: selectedLibraryId, refresh: true)
        }
      }
    }
    .task {
      await bookViewModel.loadRecentlyReadBooks(libraryId: selectedLibraryId, refresh: true)
    }
  }

  private var selectedLibrary: LibraryInfo? {
    guard !selectedLibraryId.isEmpty else { return nil }
    return LibraryManager.shared.getLibrary(id: selectedLibraryId)
  }
}

struct ReadHistorySection: View {
  let title: String
  let books: [Book]
  var bookViewModel: BookViewModel
  var onLoadMore: (() -> Void)?
  var isLoading: Bool = false

  @State private var selectedBookId: String?

  private var isBookReaderPresented: Binding<Bool> {
    Binding(
      get: { selectedBookId != nil },
      set: { if !$0 { selectedBookId = nil } }
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.title2)
        .fontWeight(.bold)
        .padding(.horizontal)

      LazyVStack(spacing: 8) {
        ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
          Button {
            selectedBookId = book.id
          } label: {
            ReadHistoryBookRow(book: book, viewModel: bookViewModel)
          }
          .buttonStyle(PlainButtonStyle())
          .onAppear {
            // Load next page when the last few items appear
            if let onLoadMore = onLoadMore, index >= books.count - 3 {
              onLoadMore()
            }
          }
        }

        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
            .padding()
        }
      }
      .padding(.horizontal)
    }
    .fullScreenCover(isPresented: isBookReaderPresented) {
      if let bookId = selectedBookId {
        BookReaderView(bookId: bookId)
      }
    }
  }
}

struct ReadHistoryBookRow: View {
  let book: Book
  var viewModel: BookViewModel
  @State private var thumbnail: UIImage?

  var body: some View {
    HStack(spacing: 12) {
      // Thumbnail
      ZStack {
        if let thumbnail = thumbnail {
          Image(uiImage: thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
              ProgressView()
            }
        }
      }
      .frame(width: 80, height: 100)
      .clipped()
      .cornerRadius(6)

      // Book info
      VStack(alignment: .leading, spacing: 6) {
        Text(book.seriesTitle)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(1)

        Text(book.metadata.title)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .lineLimit(2)

        Text("#\(Int(book.number)) - \(book.media.pagesCount) pages")
          .font(.caption)
          .foregroundColor(.secondary)

        if let progress = book.readProgress {
          Text("Last read: \(formatRelativeDate(progress.readDate))")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .animation(.default, value: thumbnail)
    .task {
      thumbnail = await viewModel.loadThumbnail(for: book.id)
    }
  }

  private func formatRelativeDate(_ date: Date) -> String {
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

    if let days = components.day {
      if days == 0 {
        if let hours = components.hour {
          if hours == 0 {
            if let minutes = components.minute {
              return "\(minutes)m ago"
            }
          }
          return "\(hours)h ago"
        }
      } else if days == 1 {
        return "Yesterday"
      } else if days < 7 {
        return "\(days) days ago"
      }
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
