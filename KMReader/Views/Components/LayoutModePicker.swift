//
//  LayoutModePicker.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct LayoutModePicker: View {
  @AppStorage("browseLayout") private var layoutMode: BrowseLayoutMode = .grid

  var body: some View {
    Button {
      withAnimation {
        layoutMode = layoutMode == .grid ? .list : .grid
      }
    } label: {
      Label(layoutMode.displayName, systemImage: layoutMode.iconName)
        .labelStyle(.iconOnly)
    }
    .adaptiveButtonStyle(.bordered)
    .controlSize(.small)
  }
}
