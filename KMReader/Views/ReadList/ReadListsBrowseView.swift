//
//  ReadListsBrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadListsBrowseView: View {
  let width: CGFloat
  let searchText: String

  private let spacing: CGFloat = 12

  @AppStorage("readListSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  @State private var viewModel = ReadListViewModel()
  @State private var layoutHelper = BrowseLayoutHelper()

  var body: some View {
    VStack(spacing: 0) {
      ReadListSortView()
        .padding(spacing)

      BrowseStateView(
        isLoading: viewModel.isLoading,
        isEmpty: viewModel.readLists.isEmpty,
        emptyIcon: "list.bullet.rectangle",
        emptyTitle: "No read lists found",
        emptyMessage: "Try selecting a different library.",
        onRetry: {
          Task {
            await loadReadLists(refresh: true)
          }
        }
      ) {
        switch browseLayout {
        case .grid:
          LazyVGrid(columns: layoutHelper.columns, spacing: spacing) {
            ForEach(Array(viewModel.readLists.enumerated()), id: \.element.id) { index, readList in
              ReadListCardView(
                readList: readList,
                width: layoutHelper.cardWidth,
                onActionCompleted: {
                  Task {
                    await loadReadLists(refresh: true)
                  }
                }
              )
              .focusPadding()
              .onAppear {
                if index >= viewModel.readLists.count - 3 {
                  Task {
                    await loadReadLists(refresh: false)
                  }
                }
              }
            }
          }
          .padding(spacing)
        case .list:
          LazyVStack(spacing: spacing) {
            ForEach(Array(viewModel.readLists.enumerated()), id: \.element.id) { index, readList in
              ReadListRowView(
                readList: readList,
                onActionCompleted: {
                  Task {
                    await loadReadLists(refresh: true)
                  }
                }
              )
              .onAppear {
                if index >= viewModel.readLists.count - 3 {
                  Task {
                    await loadReadLists(refresh: false)
                  }
                }
              }
            }
          }
          .padding(spacing)
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

      if viewModel.readLists.isEmpty {
        await loadReadLists(refresh: true)
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
    .onChange(of: sortOpts) { _, _ in
      Task {
        await loadReadLists(refresh: true)
      }
    }
    .onChange(of: searchText) { _, _ in
      Task {
        await loadReadLists(refresh: true)
      }
    }
    .onChange(of: selectedLibraryId) { _, _ in
      Task {
        await loadReadLists(refresh: true)
      }
    }
  }

  private func loadReadLists(refresh: Bool) async {
    await viewModel.loadReadLists(
      libraryId: selectedLibraryId,
      sort: sortOpts.sortString,
      searchText: searchText,
      refresh: refresh
    )
  }
}
