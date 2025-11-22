//
//  CollectionSortView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct CollectionSortView: View {
  @AppStorage("collectionSortOptions") private var sortOpts: SimpleSortOptions =
    SimpleSortOptions()
  @State private var showSortSheet = false

  var body: some View {
    HStack(spacing: 8) {
      Button {
        showSortSheet = true
      } label: {
        Image(systemName: "arrow.up.arrow.down.circle")
          .imageScale(.large)
      }
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
    }
    .sheet(isPresented: $showSortSheet) {
      SimpleSortOptionsSheet(sortOpts: $sortOpts)
    }
  }
}
