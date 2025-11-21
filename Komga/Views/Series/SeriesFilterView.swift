//
//  SeriesFilterView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SeriesFilterView: View {
  @Binding var browseOpts: SeriesBrowseOptions
  @State private var showOptionsSheet = false

  var body: some View {
    HStack(spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          if browseOpts.readStatusFilter != .all {
            FilterChip(
              label: "Read: \(browseOpts.readStatusFilter.displayName)",
              systemImage: "eye"
            )
          }

          if browseOpts.seriesStatusFilter != .all {
            FilterChip(
              label: "Status: \(browseOpts.seriesStatusFilter.displayName)",
              systemImage: "chart.bar"
            )
          }

          FilterChip(
            label:
              "\(browseOpts.sortField.displayName) \(browseOpts.sortDirection == .ascending ? "↑" : "↓")",
            systemImage: "arrow.up.arrow.down"
          )
        }
        .padding(.horizontal, 4)
      }

      Spacer()

      Button {
        showOptionsSheet = true
      } label: {
        Image(systemName: "line.3.horizontal.decrease")
      }
      .buttonStyle(.bordered)
    }
    .sheet(isPresented: $showOptionsSheet) {
      SeriesBrowseOptionsSheet(browseOpts: $browseOpts)
    }
  }
}
