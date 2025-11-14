//
//  SeriesListView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SeriesListView: View {
  let libraryId: String
  let libraryName: String

  @State private var viewModel = SeriesViewModel()
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  // Calculate number of columns and card width based on screen width
  private func calculateLayout(for width: CGFloat) -> (columns: Int, cardWidth: CGFloat) {
    let horizontalPadding: CGFloat = 32  // 16pt padding on each side
    let spacing: CGFloat = 16
    let minCardWidth: CGFloat = 120

    let availableWidth = width - horizontalPadding

    // Calculate how many columns can fit
    let maxColumns = Int((availableWidth + spacing) / (minCardWidth + spacing))
    let columns = max(2, min(maxColumns, 6))  // Minimum 2 columns, maximum 6 columns

    // Calculate actual card width
    let totalSpacing = CGFloat(columns - 1) * spacing
    let cardWidth = (availableWidth - totalSpacing) / CGFloat(columns)

    return (columns, cardWidth)
  }

  var body: some View {
    GeometryReader { geometry in
      let layout = calculateLayout(for: geometry.size.width)
      let columns = Array(
        repeating: GridItem(.fixed(layout.cardWidth), spacing: 16), count: layout.columns)

      Group {
        if viewModel.isLoading && viewModel.series.isEmpty {
          ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundColor(themeColorOption.color)
            Text(errorMessage)
              .multilineTextAlignment(.center)
            Button("Retry") {
              Task {
                await viewModel.loadSeries(libraryId: libraryId, refresh: true)
              }
            }
          }
          .padding()
        } else {
          ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
              ForEach(viewModel.series) { series in
                NavigationLink(destination: SeriesDetailView(seriesId: series.id)) {
                  SeriesCardView(series: series, viewModel: viewModel, cardWidth: layout.cardWidth)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding()

            if viewModel.isLoading {
              ProgressView()
                .padding()
            }
          }
        }
      }
    }
    .navigationTitle(libraryName)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if viewModel.series.isEmpty {
        await viewModel.loadSeries(libraryId: libraryId)
      }
    }
  }
}
