//
//  BooksBrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BooksBrowseView: View {
  let width: CGFloat
  let searchText: String
  private let spacing: CGFloat = 12

  @AppStorage("bookBrowseOptions") private var browseOpts: BookBrowseOptions = BookBrowseOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  #if os(macOS)
    @Environment(\.openWindow) private var openWindow
  #endif

  @State private var viewModel = BookViewModel()
  @State private var readerState: BookReaderState?
  @State private var hasInitialized = false
  @State private var layoutHelper = BrowseLayoutHelper()

  var body: some View {
    VStack(spacing: 0) {
      BookFilterView(browseOpts: $browseOpts)
        .padding(spacing)

      BrowseStateView(
        isLoading: viewModel.isLoading,
        isEmpty: viewModel.books.isEmpty,
        emptyIcon: "book",
        emptyTitle: "No books found",
        emptyMessage: "Try selecting a different library.",
        onRetry: {
          Task {
            await viewModel.loadBrowseBooks(
              browseOpts: browseOpts, searchText: searchText, refresh: true)
          }
        }
      ) {
        switch browseLayout {
        case .grid:
          gridView
        case .list:
          listView
        }
      }
    }
    .task {
      // Initialize layout helper
      layoutHelper = BrowseLayoutHelper(
        width: width,
        spacing: spacing,
        browseColumns: browseColumns
      )

      if viewModel.books.isEmpty {
        await viewModel.loadBrowseBooks(
          browseOpts: browseOpts, searchText: searchText, refresh: true)
      }
    }
    .onChange(of: width) { _, newWidth in
      layoutHelper = BrowseLayoutHelper(
        width: newWidth,
        spacing: spacing,
        browseColumns: browseColumns
      )
    }
    .onChange(of: browseColumns) { _, newValue in
      layoutHelper = BrowseLayoutHelper(
        width: width,
        spacing: spacing,
        browseColumns: newValue
      )
    }
    .onChange(of: browseOpts) { _, newValue in
      Task {
        await viewModel.loadBrowseBooks(browseOpts: newValue, searchText: searchText, refresh: true)
      }
    }
    .onChange(of: searchText) { _, newValue in
      Task {
        await viewModel.loadBrowseBooks(browseOpts: browseOpts, searchText: newValue, refresh: true)
      }
    }
    .onChange(of: selectedLibraryId) { _, _ in
      Task {
        await viewModel.loadBrowseBooks(
          browseOpts: browseOpts, searchText: searchText, refresh: true)
      }
    }
    .readerPresentation(readerState: $readerState)
  }

  private var gridView: some View {
    LazyVGrid(columns: layoutHelper.columns, spacing: spacing) {
      ForEach(Array(viewModel.books.enumerated()), id: \.element.id) { index, book in
        BookCardView(
          book: book,
          viewModel: viewModel,
          cardWidth: layoutHelper.cardWidth,
          onBookUpdated: {
            Task {
              await viewModel.loadBrowseBooks(
                browseOpts: browseOpts, searchText: searchText, refresh: true)
            }
          },
          showSeriesTitle: true,
        )
        .focusPadding()
        .onAppear {
          if index >= viewModel.books.count - 3 {
            Task {
              await viewModel.loadBrowseBooks(
                browseOpts: browseOpts, searchText: searchText, refresh: false)
            }
          }
        }
      }
    }
    .padding(spacing)
  }

  private var listView: some View {
    LazyVStack(spacing: spacing) {
      ForEach(Array(viewModel.books.enumerated()), id: \.element.id) { index, book in
        BookRowView(
          book: book,
          viewModel: viewModel,
          onReadBook: { incognito in
            readerState = BookReaderState(book: book, incognito: incognito)
          },
          onBookUpdated: {
            Task {
              await viewModel.loadBrowseBooks(
                browseOpts: browseOpts, searchText: searchText, refresh: true)
            }
          },
          showSeriesTitle: true
        )
        .onAppear {
          if index >= viewModel.books.count - 3 {
            Task {
              await viewModel.loadBrowseBooks(
                browseOpts: browseOpts, searchText: searchText, refresh: false)
            }
          }
        }
      }
    }
    .padding(spacing)
  }
}
