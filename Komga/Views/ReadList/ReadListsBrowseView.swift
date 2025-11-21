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

  private let spacing: CGFloat = 8

  @AppStorage("readListSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid
  @State private var viewModel = ReadListViewModel()

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
      ReadListSortView()
        .padding(spacing)

      if viewModel.isLoading && viewModel.readLists.isEmpty {
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
              await loadReadLists(refresh: true)
            }
          }
        }
        .padding()
      } else if viewModel.readLists.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "list.bullet.rectangle")
            .font(.system(size: 40))
            .foregroundColor(.secondary)
          Text("No read lists found")
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
            ForEach(Array(viewModel.readLists.enumerated()), id: \.element.id) { index, readList in
              ReadListCardView(readList: readList, width: cardWidth)
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

        if viewModel.isLoading {
          ProgressView()
            .padding()
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
