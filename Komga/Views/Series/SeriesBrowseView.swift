//
//  SeriesBrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SeriesBrowseView: View {
  let width: CGFloat
  let height: CGFloat
  let searchText: String
  let spacing: CGFloat = 12

  @AppStorage("seriesBrowseOptions") private var browseOpts: SeriesBrowseOptions =
    SeriesBrowseOptions()
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @AppStorage("browseLayout") private var browseLayout: BrowseLayoutMode = .grid

  @State private var viewModel = SeriesViewModel()

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
      SeriesFilterView(browseOpts: $browseOpts)
        .padding(spacing)

      BrowseStateView(
        isLoading: viewModel.isLoading,
        isEmpty: viewModel.series.isEmpty,
        errorMessage: viewModel.errorMessage,
        emptyIcon: "books.vertical",
        emptyTitle: "No series found",
        emptyMessage: "Try selecting a different library.",
        themeColor: themeColorOption.color,
        onRetry: {
          Task {
            await viewModel.loadSeries(
              browseOpts: browseOpts, searchText: searchText, refresh: true)
          }
        }
      ) {
        switch browseLayout {
        case .grid:
          LazyVGrid(columns: layoutHelper.columns, spacing: spacing) {
            ForEach(Array(viewModel.series.enumerated()), id: \.element.id) { index, series in
              NavigationLink(value: NavDestination.seriesDetail(seriesId: series.id)) {
                SeriesCardView(
                  series: series,
                  cardWidth: layoutHelper.cardWidth,
                  onActionCompleted: {
                    Task {
                      await viewModel.loadSeries(
                        browseOpts: browseOpts, searchText: searchText, refresh: true)
                    }
                  }
                )
              }
              .buttonStyle(.plain)
              .onAppear {
                if index >= viewModel.series.count - 3 {
                  Task {
                    await viewModel.loadSeries(
                      browseOpts: browseOpts, searchText: searchText, refresh: false)
                  }
                }
              }
            }
          }
          .padding(spacing)
        case .list:
          LazyVStack(spacing: spacing) {
            ForEach(Array(viewModel.series.enumerated()), id: \.element.id) { index, series in
              NavigationLink(value: NavDestination.seriesDetail(seriesId: series.id)) {
                SeriesRowView(
                  series: series,
                  onActionCompleted: {
                    Task {
                      await viewModel.loadSeries(
                        browseOpts: browseOpts, searchText: searchText, refresh: true)
                    }
                  }
                )
              }
              .buttonStyle(.plain)
              .onAppear {
                if index >= viewModel.series.count - 3 {
                  Task {
                    await viewModel.loadSeries(
                      browseOpts: browseOpts, searchText: searchText, refresh: false)
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
      if viewModel.series.isEmpty {
        await viewModel.loadSeries(browseOpts: browseOpts, searchText: searchText, refresh: true)
      }
    }
    .onChange(of: browseOpts) { _, newValue in
      Task {
        await viewModel.loadSeries(browseOpts: newValue, searchText: searchText, refresh: true)
      }
    }
    .onChange(of: searchText) { _, newValue in
      Task {
        await viewModel.loadSeries(browseOpts: browseOpts, searchText: newValue, refresh: true)
      }
    }
    .onChange(of: selectedLibraryId) { _, newValue in
      browseOpts.libraryId = newValue
    }
    .onAppear {
      browseOpts.libraryId = selectedLibraryId
    }
  }
}
