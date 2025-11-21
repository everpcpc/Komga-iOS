//
//  BrowseStateView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

/// Generic state view for browse screens
struct BrowseStateView<Content: View>: View {
  let isLoading: Bool
  let isEmpty: Bool
  let errorMessage: String?
  let emptyIcon: String
  let emptyTitle: String
  let emptyMessage: String
  let themeColor: Color
  let onRetry: () -> Void
  @ViewBuilder let content: () -> Content

  var body: some View {
    Group {
      if isLoading && isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else if let errorMessage = errorMessage {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.largeTitle)
            .foregroundColor(themeColor)
          Text(errorMessage)
            .multilineTextAlignment(.center)
          Button("Retry") {
            onRetry()
          }
        }
        .padding()
      } else if isEmpty {
        VStack(spacing: 12) {
          Image(systemName: emptyIcon)
            .font(.system(size: 40))
            .foregroundColor(.secondary)
          Text(emptyTitle)
            .font(.headline)
          Text(emptyMessage)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
      } else {
        content()

        if isLoading {
          ProgressView()
            .padding()
        }
      }
    }
  }
}
