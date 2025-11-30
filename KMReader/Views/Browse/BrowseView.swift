//
//  BrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BrowseView: View {
  @AppStorage("browseContent") private var browseContent: BrowseContentType = .series
  @State private var searchQuery: String = ""
  @State private var activeSearchText: String = ""
  @State private var containerWidth: CGFloat = 0

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        ScrollView {
          VStack(spacing: 0) {
            Picker("Content Type", selection: $browseContent) {
              ForEach(BrowseContentType.allCases) { type in
                Text(type.displayName).tag(type)
              }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if containerWidth > 0 {
              contentView(width: containerWidth)
            }
          }
        }
        .handleNavigation()
        .inlineNavigationBarTitle("Browse")
        .searchable(text: $searchQuery)
        .onSubmit(of: .search) {
          activeSearchText = searchQuery
        }
        .onChange(of: searchQuery) { _, newValue in
          if newValue.isEmpty {
            activeSearchText = ""
          }
        }
        .onChange(of: geometry.size.width) { _, newWidth in
          containerWidth = newWidth
        }
        .onAppear {
          containerWidth = geometry.size.width
        }
      }
    }
  }

  @ViewBuilder
  private func contentView(width: CGFloat) -> some View {
    switch browseContent {
    case .series:
      SeriesBrowseView(
        width: width,
        searchText: activeSearchText
      )
    case .books:
      BooksBrowseView(
        width: width,
        searchText: activeSearchText
      )
    case .collections:
      CollectionsBrowseView(
        width: width,
        searchText: activeSearchText
      )
    case .readlists:
      ReadListsBrowseView(
        width: width,
        searchText: activeSearchText
      )
    }
  }
}
