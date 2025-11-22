//
//  UnreadIndicator.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct UnreadIndicator: View {
  let size: CGFloat

  init(size: CGFloat = 12) {
    self.size = size
  }

  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  var body: some View {
    Circle()
      .fill(themeColor.color)
      .frame(width: size, height: size)
      .padding(4)
  }
}
