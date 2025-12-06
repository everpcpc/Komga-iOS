//
//  LayoutModePicker.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct LayoutModePicker: View {
  @AppStorage("browseLayout") private var layoutMode: BrowseLayoutMode = .grid

  private var animatedSelection: Binding<BrowseLayoutMode> {
    Binding(
      get: { layoutMode },
      set: { newValue in
        withAnimation {
          layoutMode = newValue
        }
      }
    )
  }

  var body: some View {
    Picker("Layout Mode", selection: animatedSelection) {
      ForEach(BrowseLayoutMode.allCases) { mode in
        Image(systemName: mode.iconName)
          .tag(mode)
      }
    }
    .pickerStyle(.segmented)
    .scaleEffect(0.8)
    .frame(width: 80, height: 28)
    .clipped()
  }
}
