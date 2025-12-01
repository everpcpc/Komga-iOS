//
//  UnreadCountBadge.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct UnreadCountBadge: View {
  let count: Int
  let size: CGFloat

  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  init(count: Int, size: CGFloat = 13) {
    self.count = count
    self.size = size
  }

  var body: some View {
    Text("\(count)")
      .font(.system(size: size))
      .foregroundColor(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(themeColor.color)
      .clipShape(Capsule())
      .padding(2)
  }
}

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
