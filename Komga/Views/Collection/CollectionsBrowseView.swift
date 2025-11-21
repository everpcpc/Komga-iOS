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

  private let spacing: CGFloat = 8

  @AppStorage("collectionSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  @State private var viewModel = CollectionViewModel()

  private var availableWidth: CGFloat {
    width - spacing * 2
  }

  private var isLandscape: Bool {
    width > height
  }

  private var columnsCount: Int {
    isLandscape ? browseColumns.landscape : browseColumns.portrait
  }

  private var cardWidth: CGFloat {
    guard columnsCount > 0 else { return availableWidth }
    let totalSpacing = CGFloat(columnsCount - 1) * spacing
    return (availableWidth - totalSpacing) / CGFloat(columnsCount)
  }

  private var columns: [GridItem] {
    Array(repeating: GridItem(.fixed(cardWidth), spacing: spacing), count: max(columnsCount, 1))
  }

  var body: some View {
    VStack(spacing: 0) {
      CollectionSortView()
        .padding(spacing)

      if viewModel.isLoading && viewModel.collections.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else if let errorMessage = viewModel.errorMessage {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundColor(themeColorOption.color)
          Text(errorMessage)
            .multilineTextAlignment(.center)
          Button("Retry") {
            Task {
              await loadCollections(refresh: true)
            }
          }
        }
        .padding()
      } else if viewModel.collections.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "square.grid.2x2")
            .font(.system(size: 40))
            .foregroundColor(.secondary)
          Text("No collections found")
            .font(.headline)
          Text("Try selecting a different library.")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
      } else {
        switch browseLayout {
        case .grid:
          LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(viewModel.collections.enumerated()), id: \.element.id) {
              index, collection in
              CollectionCardView(collection: collection, width: cardWidth)
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

        if viewModel.isLoading {
          ProgressView()
            .padding()
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
