//
//  FilterChip.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct FilterChip: View {
  let label: String
  let systemImage: String

  @Binding var openSheet: Bool

  var body: some View {
    Button {
      openSheet = true
    } label: {
      HStack(spacing: 4) {
        Image(systemName: systemImage)
          .font(.caption2)
        Text(label)
          .font(.caption)
          .fontWeight(.medium)
      }
    }
    .adaptiveButtonStyle(.bordered)
    .controlSize(.mini)
  }
}
