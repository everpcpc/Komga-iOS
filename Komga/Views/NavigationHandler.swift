//
//  NavigationHandler.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

extension View {
  func handleNavigation() -> some View {
    self
      .navigationDestination(for: NavDestination.self) { destination in
        switch destination {
        case .seriesDetail(let seriesId):
          SeriesDetailView(seriesId: seriesId)
        case .bookDetail(let bookId):
          BookDetailView(bookId: bookId)

        case .settingsAppearance:
          SettingsAppearanceView()
        case .settingsCache:
          SettingsCacheView()
        case .settingsLibraries:
          SettingsLibrariesView()
        }
      }
  }
}
