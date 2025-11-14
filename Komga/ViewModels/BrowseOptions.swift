//
//  BrowseOptions.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

@MainActor
@Observable
class BrowseOptions {
  var libraryId: String = ""
  var readStatusFilter: ReadStatusFilter = .all
  var seriesStatusFilter: SeriesStatusFilter = .all
  var sortField: SeriesSortField = .name
  var sortDirection: SortDirection = .ascending

  // Computed property to generate sort string for API
  var sortString: String {
    if sortField == .random {
      return "random"
    }
    return "\(sortField.rawValue),\(sortDirection.rawValue)"
  }
}
