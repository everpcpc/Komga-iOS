//
//  PageLayout.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

enum PageLayout: String, CaseIterable, Hashable {
  case single = "single"
  case dual = "dual"

  var displayName: String {
    switch self {
    case .single:
      return "Single Page"
    case .dual:
      return "Dual Page"
    }
  }

  var icon: String {
    switch self {
    case .single:
      return "rectangle.portrait"
    case .dual:
      return "rectangle.split.2x1"
    }
  }
}
