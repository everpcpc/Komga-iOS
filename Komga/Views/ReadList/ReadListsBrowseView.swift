//
//  ReadListsBrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadListsBrowseView: View {
  let width: CGFloat
  let height: CGFloat
  let searchText: String

  private let spacing: CGFloat = 12

  @AppStorage("readListSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  @State private var viewModel = ReadListViewModel()

  private var layoutHelper: BrowseLayoutHelper {
    BrowseLayoutHelper(
      width: width,
      height: height,
      spacing: spacing,
      browseColumns: browseColumns
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      ReadListSortView()
        .padding(spacing)

      BrowseStateView(
        isLoading: viewModel.isLoading,
        isEmpty: viewModel.readLists.isEmpty,
        errorMessage: viewModel.errorMessage,
        emptyIcon: "list.bullet.rectangle",
        emptyTitle: "No read lists found",
        emptyMessage: "Try selecting a different library.",
        themeColor: themeColorOption.color,
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
              ReadListCardView(readList: readList, width: layoutHelper.cardWidth)
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
              ReadListRowView(readList: readList)
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
      if viewModel.readLists.isEmpty {
        await loadReadLists(refresh: true)
      }
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
