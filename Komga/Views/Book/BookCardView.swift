//
//  BookCardView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BookCardView: View {
  let book: Book
  var viewModel: BookViewModel
  let cardWidth: CGFloat
  var onBookUpdated: (() -> Void)? = nil

  @AppStorage("showBookCardSeriesTitle") private var showSeriesTitle: Bool = true
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  @State private var readerState: BookReaderState?
  @State private var showReadListPicker = false

  private var thumbnailURL: URL? {
    BookService.shared.getBookThumbnailURL(id: book.id)
  }

  private var isBookReaderPresented: Binding<Bool> {
    Binding(
      get: { readerState != nil },
      set: { if !$0 { readerState = nil } }
    )
  }

  private var progress: Double {
    guard let readProgress = book.readProgress else { return 0 }
    guard book.media.pagesCount > 0 else { return 0 }
    return Double(readProgress.page) / Double(book.media.pagesCount)
  }

  private var isCompleted: Bool {
    book.readProgress?.completed ?? false
  }

  private var isInProgress: Bool {
    guard let readProgress = book.readProgress else { return false }
    return !readProgress.completed
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ThumbnailImage(url: thumbnailURL, width: cardWidth)
        .overlay(alignment: .topTrailing) {
          if book.readProgress == nil {
            Circle()
              .fill(themeColorOption.color)
              .frame(width: 12, height: 12)
              .padding(4)
          }
        }
        .overlay(alignment: .topTrailing) {
          if book.readProgress == nil {
            Circle()
              .fill(themeColorOption.color)
              .frame(width: 12, height: 12)
              .padding(4)
          }
        }
        .overlay(alignment: .bottom) {
          if isInProgress {
            GeometryReader { geometry in
              ZStack(alignment: .leading) {
                Rectangle()
                  .fill(Color.gray.opacity(0.2))
                  .frame(height: 4)
                  .cornerRadius(2)

                Rectangle()
                  .fill(themeColorOption.color)
                  .frame(width: geometry.size.width * progress, height: 4)
                  .cornerRadius(2)
              }
            }
            .frame(height: 4)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
          }
        }

      VStack(alignment: .leading, spacing: 2) {
        if showSeriesTitle {
          Text(book.seriesTitle)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(1)
        }
        Text("\(book.metadata.number) - \(book.metadata.title)")
          .font(.caption)
          .foregroundColor(.primary)
          .lineLimit(1)

        Group {
          if book.deleted {
            Text("Unavailable")
              .foregroundColor(.red)
          } else {
            HStack(spacing: 4) {
              Text("\(book.media.pagesCount) pages · \(book.size)")
              if book.oneshot {
                Text("•")
                Text("Oneshot")
                  .foregroundColor(.blue)
              }
            }
            .foregroundColor(.secondary)
            .lineLimit(1)
          }
        }.font(.caption2)
      }
      .frame(width: cardWidth, alignment: .leading)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      readerState = BookReaderState(bookId: book.id, incognito: false)
    }
    .contextMenu {
      BookContextMenu(
        book: book,
        viewModel: viewModel,
        onReadBook: { incognito in
          readerState = BookReaderState(bookId: book.id, incognito: incognito)
        },
        onActionCompleted: onBookUpdated,
        onShowReadListPicker: {
          showReadListPicker = true
        }
      )
    }
    .sheet(isPresented: $showReadListPicker) {
      ReadListPickerSheet(
        bookIds: [book.id],
        onSelect: { readListId in
          addToReadList(readListId: readListId)
        },
        onComplete: {
          // Create already adds book, just refresh
          onBookUpdated?()
        }
      )
    }
    .fullScreenCover(
      isPresented: isBookReaderPresented,
      onDismiss: {
        onBookUpdated?()
      }
    ) {
      if let state = readerState, let bookId = state.bookId {
        BookReaderView(bookId: bookId, incognito: state.incognito)
      }
    }
  }

  private func addToReadList(readListId: String) {
    Task {
      do {
        try await ReadListService.shared.addBooksToReadList(
          readListId: readListId,
          bookIds: [book.id]
        )
        await MainActor.run {
          onBookUpdated?()
        }
      } catch {
        // Handle error if needed
      }
    }
  }
}
