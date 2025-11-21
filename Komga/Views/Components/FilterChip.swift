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

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: systemImage)
        .font(.caption2)
      Text(label)
        .font(.caption)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.secondary.opacity(0.2))
    .cornerRadius(8)
  }
}
