//
//  UnreadCountBadge.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct UnreadCountBadge: View {
  let count: Int
  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  var body: some View {
    ZStack {
      // Outer capsule with background color
      Text("\(count)")
        .font(.caption.weight(.bold))
        .foregroundColor(.clear)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.systemBackground))
        .clipShape(Capsule())

      // Inner capsule with theme color
      Text("\(count)")
        .font(.caption.weight(.bold))
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(themeColor.color)
        .clipShape(Capsule())
    }
    .padding(-8)
  }
}

#Preview {
  UnreadCountBadge(count: 12)
}
