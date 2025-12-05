//
//  ResetButton.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ResetButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label("Reset", systemImage: "arrow.uturn.backward")
        .frame(maxWidth: .infinity)
    }
    .adaptiveButtonStyle(.bordered)
  }
}
