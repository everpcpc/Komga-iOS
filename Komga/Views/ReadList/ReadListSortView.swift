//
//  ReadListSortView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadListSortView: View {
  @AppStorage("readListSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @State private var showSortSheet = false

  var body: some View {
    HStack(spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          FilterChip(
            label:
              "\(sortOpts.sortField.displayName) \(sortOpts.sortDirection == .ascending ? "↑" : "↓")",
            systemImage: "arrow.up.arrow.down"
          )
        }
        .padding(.horizontal, 4)
      }

      Spacer()

      Button {
        showSortSheet = true
      } label: {
        Image(systemName: "arrow.up.arrow.down")
      }
      .buttonStyle(.bordered)
    }
    .sheet(isPresented: $showSortSheet) {
      SimpleSortOptionsSheet(sortOpts: $sortOpts)
    }
  }
}
