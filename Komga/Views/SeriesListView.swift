//
//  SeriesListView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SeriesListView: View {
  let libraryId: String
  let width: CGFloat
  let spacing: CGFloat = 16
  @State private var viewModel = SeriesViewModel()
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  var availableWidth: CGFloat {
    width - spacing * 2
  }

  var columnsCount: Int {
    let minCardWidth: CGFloat = 120
    let maxColumns = Int((availableWidth + spacing) / (minCardWidth + spacing))
    return max(2, min(maxColumns, 6))
  }

  var cardWidth: CGFloat {
    let totalSpacing = CGFloat(columnsCount - 1) * spacing
    return (availableWidth - totalSpacing) / CGFloat(columnsCount)
  }

  var columns: [GridItem] {
    Array(
      repeating: GridItem(.fixed(cardWidth), spacing: 16),
      count: columnsCount)
  }

  var body: some View {
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
        LazyVGrid(columns: columns, spacing: spacing) {
          ForEach(Array(viewModel.series.enumerated()), id: \.element.id) { index, series in
            NavigationLink(destination: SeriesDetailView(seriesId: series.id)) {
              SeriesCardView(
                series: series, viewModel: viewModel, cardWidth: cardWidth)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
              // Load next page when the last few items appear
              if index >= viewModel.series.count - 3 {
                Task {
                  await viewModel.loadSeries(libraryId: libraryId, refresh: false)
                }
              }
            }
          }
        }
        .padding(.horizontal, spacing)

        if viewModel.isLoading {
          ProgressView()
            .padding()
        }
      }
    }
    .animation(.default, value: viewModel.series)
    .task {
      await viewModel.loadSeries(libraryId: libraryId, refresh: true)
    }
    .onChange(of: libraryId) {
      Task {
        await viewModel.loadSeries(libraryId: libraryId, refresh: true)
      }
    }
  }
}
