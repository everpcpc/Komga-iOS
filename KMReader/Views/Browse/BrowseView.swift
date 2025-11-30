//
//  BrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BrowseView: View {
  @AppStorage("browseContent") private var browseContent: BrowseContentType = .series
  @AppStorage("browseColumns") private var browseColumns: BrowseColumns = BrowseColumns()
  @State private var searchQuery: String = ""
  @State private var activeSearchText: String = ""
  @State private var contentWidth: CGFloat = 0
  @State private var layoutHelper = BrowseLayoutHelper()

  private let spacing: CGFloat = 12
  // SwiftUI's default horizontal padding is 16 on each side (32 total)
  private let horizontalPadding: CGFloat = 16

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          HStack {
            Spacer()
            Picker("Content", selection: $browseContent) {
              ForEach(BrowseContentType.allCases) { type in
                Text(type.displayName).tag(type)
              }
            }
            .pickerStyle(.segmented)
            Spacer()
          }
          .padding(.horizontal, horizontalPadding)
          .padding(.vertical, spacing)

          if contentWidth > 0 {
            contentView(layoutHelper: layoutHelper)
              .padding(.horizontal, horizontalPadding)
              .padding(.vertical, spacing)
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
      .onGeometryChange(for: CGSize.self) { geometry in
        geometry.size
      } action: { newSize in
        let newContentWidth = max(0, newSize.width - horizontalPadding * 2)
        if abs(contentWidth - newContentWidth) > 1 {
          contentWidth = newContentWidth
          layoutHelper = BrowseLayoutHelper(
            width: newContentWidth,
            spacing: spacing,
            browseColumns: browseColumns
          )
        }
      }
      .onChange(of: browseColumns) { _, _ in
        if contentWidth > 0 {
          layoutHelper = BrowseLayoutHelper(
            width: contentWidth,
            spacing: spacing,
            browseColumns: browseColumns
          )
        }
      }
    }
  }

  @ViewBuilder
  private func contentView(layoutHelper: BrowseLayoutHelper) -> some View {
    switch browseContent {
    case .series:
      SeriesBrowseView(
        layoutHelper: layoutHelper,
        searchText: activeSearchText
      )
    case .books:
      BooksBrowseView(
        layoutHelper: layoutHelper,
        searchText: activeSearchText
      )
    case .collections:
      CollectionsBrowseView(
        layoutHelper: layoutHelper,
        searchText: activeSearchText
      )
    case .readlists:
      ReadListsBrowseView(
        layoutHelper: layoutHelper,
        searchText: activeSearchText
      )
    }
  }
}
