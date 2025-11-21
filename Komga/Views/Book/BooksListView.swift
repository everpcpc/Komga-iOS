//
//  BooksListView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

// Books list view for series detail
struct BooksListViewForSeries: View {
  let seriesId: String
  @Bindable var bookViewModel: BookViewModel
  var onReadBook: (String, Bool) -> Void
  @AppStorage("seriesBookBrowseOptions") private var browseOpts: BookBrowseOptions =
    BookBrowseOptions()

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Books")
          .font(.headline)

        Spacer()

        BookFilterView(browseOpts: $browseOpts)
      }

      if bookViewModel.isLoading && bookViewModel.books.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        LazyVStack(spacing: 8) {
          ForEach(bookViewModel.books) { book in
            BookRowView(
              book: book,
              viewModel: bookViewModel,
              onReadBook: { incognito in
                onReadBook(book.id, incognito)
              },
              onBookUpdated: {
                refreshBooks()
              }
            )
            .onAppear {
              if book.id == bookViewModel.books.last?.id {
                Task {
                  await bookViewModel.loadMoreBooks(seriesId: seriesId)
                }
              }
            }
          }

          if bookViewModel.isLoading && !bookViewModel.books.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding()
          }
        }
      }
    }
    .task(id: seriesId) {
      await bookViewModel.loadBooks(seriesId: seriesId, browseOpts: browseOpts)
    }
    .onChange(of: browseOpts) {
      Task {
        await bookViewModel.loadBooks(seriesId: seriesId, browseOpts: browseOpts)
      }
    }
  }
}

extension BooksListViewForSeries {
  fileprivate func refreshBooks() {
    Task {
      await bookViewModel.loadBooks(seriesId: seriesId, browseOpts: browseOpts)
    }
  }
}

// Books list view for read list
struct BooksListViewForReadList: View {
  let readListId: String
  @Bindable var bookViewModel: BookViewModel
  var onReadBook: (String, Bool) -> Void
  @AppStorage("readListBookBrowseOptions") private var browseOpts: BookBrowseOptions =
    BookBrowseOptions()

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Books")
          .font(.headline)

        Spacer()

        BookFilterView(browseOpts: $browseOpts)
      }

      if bookViewModel.isLoading && bookViewModel.books.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        LazyVStack(spacing: 8) {
          ForEach(bookViewModel.books) { book in
            BookRowView(
              book: book,
              viewModel: bookViewModel,
              onReadBook: { incognito in
                onReadBook(book.id, incognito)
              },
              onBookUpdated: {
                refreshBooks()
              },
              showSeriesTitle: true
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(role: .destructive) {
                Task {
                  do {
                    try await ReadListService.shared.removeBookFromReadList(
                      readListId: readListId, bookId: book.id)
                    await bookViewModel.loadReadListBooks(
                      readListId: readListId, browseOpts: browseOpts, refresh: true)
                  } catch {
                  }
                }
              } label: {
                Label("Remove", systemImage: "trash")
              }
            }
            .onAppear {
              if book.id == bookViewModel.books.last?.id {
                Task {
                  await bookViewModel.loadReadListBooks(
                    readListId: readListId, browseOpts: browseOpts, refresh: false)
                }
              }
            }
          }

          if bookViewModel.isLoading && !bookViewModel.books.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding()
          }
        }
      }
    }
    .task(id: readListId) {
      await bookViewModel.loadReadListBooks(
        readListId: readListId, browseOpts: browseOpts, refresh: true)
    }
    .onChange(of: browseOpts) {
      Task {
        await bookViewModel.loadReadListBooks(
          readListId: readListId, browseOpts: browseOpts, refresh: true)
      }
    }
  }
}

extension BooksListViewForReadList {
  fileprivate func refreshBooks() {
    Task {
      await bookViewModel.loadReadListBooks(
        readListId: readListId, browseOpts: browseOpts, refresh: true)
    }
  }
}
