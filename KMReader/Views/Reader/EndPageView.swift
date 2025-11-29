//
//  EndPageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct EndPageView: View {
  let nextBook: Book?
  let onDismiss: () -> Void
  let onNextBook: (String) -> Void
  let isRTL: Bool

  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 16) {

        // Next book button for RTL
        if isRTL, let nextBook = nextBook {
          Button {
            onNextBook(nextBook.id)
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "arrow.left")
              Text("Next")
            }
          }
          .buttonStyle(.borderedProminent)
        }

        // Dismiss button
        Button {
          onDismiss()
        } label: {
          HStack(spacing: 8) {
            if !isRTL {
              Image(systemName: "xmark")
            }
            Text("Close")
            if isRTL {
              Image(systemName: "xmark")
            }
          }
        }
        .buttonStyle(.bordered)

        // Next book button
        if !isRTL, let nextBook = nextBook {
          Button {
            onNextBook(nextBook.id)
          } label: {
            HStack(spacing: 8) {
              Text("Next")
              Image(systemName: "arrow.right")
            }
          }
          .buttonStyle(.borderedProminent)
        }
      }
      NextBookInfoView(nextBook: nextBook)
    }
  }
}
