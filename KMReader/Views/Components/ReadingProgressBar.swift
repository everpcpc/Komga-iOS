//
//  ReadingProgressBar.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadingProgressBar: View {
  let progress: Double
  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(Color.gray.opacity(0.2))
          .frame(height: 4)
          .cornerRadius(2)

        Rectangle()
          .fill(themeColor.color)
          .frame(width: geometry.size.width * progress, height: 4)
          .cornerRadius(2)
      }
    }
    .frame(height: 4)
    .padding(4)
  }
}
