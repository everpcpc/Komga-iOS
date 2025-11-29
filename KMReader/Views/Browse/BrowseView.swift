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

            contentView(for: geometry.size)
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
      }
    }
  }

  @ViewBuilder
  private func contentView(for size: CGSize) -> some View {
    switch browseContent {
    case .series:
      SeriesBrowseView(
        width: size.width,
        height: size.height,
        searchText: activeSearchText
      )
    case .books:
      BooksBrowseView(
        width: size.width,
        height: size.height,
        searchText: activeSearchText
      )
    case .collections:
      CollectionsBrowseView(
        width: size.width,
        height: size.height,
        searchText: activeSearchText
      )
    case .readlists:
      ReadListsBrowseView(
        width: size.width,
        height: size.height,
        searchText: activeSearchText
      )
    }
  }
}
