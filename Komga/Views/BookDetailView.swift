//
//  BookDetailView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BookDetailView: View {
  let bookId: String

  @State private var book: Book?
  @State private var isLoading = true
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  private var thumbnailURL: URL? {
    return BookService.shared.getBookThumbnailURL(id: bookId)
  }

  private var progress: Double {
    guard let book = book, let readProgress = book.readProgress else { return 0 }
    guard book.media.pagesCount > 0 else { return 0 }
    return Double(readProgress.page) / Double(book.media.pagesCount)
  }

  private var isCompleted: Bool {
    book?.readProgress?.completed ?? false
  }

  private var isInProgress: Bool {
    guard let readProgress = book?.readProgress else { return false }
    return !readProgress.completed
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let book = book {
          HStack(alignment: .top, spacing: 16) {
            ThumbnailImage(url: thumbnailURL, width: 120)

            VStack(alignment: .leading, spacing: 8) {
              Text(book.metadata.title)
                .font(.title2)
                .fixedSize(horizontal: false, vertical: true)

              Text(book.seriesTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

              HStack(spacing: 4) {
                Image(systemName: "book")
                  .font(.caption)
                Text("#\(book.metadata.number) · \(book.media.pagesCount) pages")
              }
              .font(.caption)
              .foregroundColor(.secondary)

              if book.deleted {
                Text("Unavailable")
                  .font(.caption)
                  .foregroundColor(.red)
              }

              if let readProgress = book.readProgress {
                HStack(spacing: 4) {
                  Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.pages")
                    .font(.caption)
                  if isCompleted {
                    Text("Completed")
                  } else {
                    Text("Page \(readProgress.page) / \(book.media.pagesCount)")
                  }
                }
                .font(.caption)
                .foregroundColor(isCompleted ? .green : themeColorOption.color)
              } else {
                HStack(spacing: 4) {
                  Image(systemName: "circle")
                    .font(.caption)
                  Text("Unread")
                }
                .font(.caption)
                .foregroundColor(.secondary)
              }
            }

            Spacer()
          }

          Divider()

          VStack(alignment: .leading, spacing: 12) {
            InfoRow(
              label: "SIZE",
              value: book.size,
              icon: "internaldrive"
            )

            InfoRow(
              label: "FORMAT",
              value: book.media.mediaType.uppercased(),
              icon: "doc.text"
            )

            InfoRow(
              label: "FILE",
              value: book.url,
              icon: "document"
            )

            InfoRow(
              label: "CREATED",
              value: formatDate(book.created),
              icon: "calendar.badge.plus"
            )

            InfoRow(
              label: "LAST MODIFIED",
              value: formatDate(book.lastModified),
              icon: "calendar.badge.clock"
            )

            if let authors = book.metadata.authors, !authors.isEmpty {
              InfoRow(
                label: "AUTHORS",
                value: authors.map { $0.name }.joined(separator: ", "),
                icon: "person"
              )
            }

            if let releaseDate = book.metadata.releaseDate {
              InfoRow(
                label: "RELEASE DATE",
                value: releaseDate,
                icon: "calendar"
              )
            }

            if let isbn = book.metadata.isbn, !isbn.isEmpty {
              InfoRow(
                label: "ISBN",
                value: isbn,
                icon: "barcode"
              )
            }
          }

          if let summary = book.metadata.summary, !summary.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 4) {
                Image(systemName: "text.alignleft")
                  .font(.caption)
                Text("SUMMARY")
                  .font(.caption)
                  .fontWeight(.semibold)
              }
              .foregroundColor(.secondary)

              Text(summary)
                .font(.body)
                .foregroundColor(.primary)
            }
          }
        } else if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundColor(.secondary)
            Text("Failed to load book details")
              .font(.headline)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .padding()
    }
    .navigationTitle("Book Details")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await loadBook()
    }
  }

  private func loadBook() async {
    do {
      book = try await BookService.shared.getBook(id: bookId)
      isLoading = false
    } catch {
      isLoading = false
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

// MARK: - Info Row

struct InfoRow: View {
  let label: String
  let value: String
  let icon: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Label {
        Text(label)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
      } icon: {
        Image(systemName: icon)
          .font(.caption)
          .foregroundColor(.secondary)
          .frame(width: 16)
      }

      Spacer()

      Text(value)
        .font(.caption)
        .foregroundColor(.primary)
        .multilineTextAlignment(.trailing)
        .lineLimit(2)
    }
  }
}
