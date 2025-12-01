//
//  ReaderBackground.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

enum ReaderBackground: String, CaseIterable, Hashable {
  case black = "black"
  case white = "white"
  case gray = "gray"
  case system = "system"

  var displayName: String {
    switch self {
    case .black: return "Black"
    case .white: return "White"
    case .gray: return "Gray"
    case .system: return "System"
    }
  }

  var color: Color {
    switch self {
    case .black: return .black
    case .white: return .white
    case .gray: return .gray
    case .system: return PlatformHelper.systemBackgroundColor
    }
  }
}

private struct ReaderBackgroundPreferenceKey: EnvironmentKey {
  static let defaultValue: ReaderBackground = .system
}

extension EnvironmentValues {
  var readerBackgroundPreference: ReaderBackground {
    get { self[ReaderBackgroundPreferenceKey.self] }
    set { self[ReaderBackgroundPreferenceKey.self] = newValue }
  }
}
