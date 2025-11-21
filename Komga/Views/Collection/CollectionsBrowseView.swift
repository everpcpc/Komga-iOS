//
//  CollectionsBrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct CollectionsBrowseView: View {
  let width: CGFloat
  let height: CGFloat
  let searchText: String

  private let spacing: CGFloat = 12

  @AppStorage("collectionSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  @State private var viewModel = CollectionViewModel()

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
      CollectionSortView()
        .padding(spacing)

      BrowseStateView(
        isLoading: viewModel.isLoading,
        isEmpty: viewModel.collections.isEmpty,
        errorMessage: viewModel.errorMessage,
        emptyIcon: "square.grid.2x2",
        emptyTitle: "No collections found",
        emptyMessage: "Try selecting a different library.",
        themeColor: themeColorOption.color,
        onRetry: {
          Task {
            await loadCollections(refresh: true)
          }
        }
      ) {
        switch browseLayout {
        case .grid:
          LazyVGrid(columns: layoutHelper.columns, spacing: spacing) {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) {
              index, collection in
              CollectionCardView(collection: collection, width: layoutHelper.cardWidth)
                .onAppear {
                  if index >= viewModel.collections.count - 3 {
                    Task {
                      await loadCollections(refresh: false)
                    }
                  }
                }
            }
          }
          .padding(spacing)
        case .list:
          LazyVStack(spacing: spacing) {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) {
              index, collection in
              CollectionRowView(collection: collection)
                .onAppear {
                  if index >= viewModel.collections.count - 3 {
                    Task {
                      await loadCollections(refresh: false)
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
      if viewModel.collections.isEmpty {
        await loadCollections(refresh: true)
      }
    }
    .onChange(of: sortOpts) { _, _ in
      Task {
        await loadCollections(refresh: true)
      }
    }
    .onChange(of: searchText) { _, _ in
      Task {
        await loadCollections(refresh: true)
      }
    }
  }

  private func loadCollections(refresh: Bool) async {
    await viewModel.loadCollections(
      libraryId: selectedLibraryId,
      sort: sortOpts.sortString,
      searchText: searchText,
      refresh: refresh
    )
  }
}
