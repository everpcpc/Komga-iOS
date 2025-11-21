//
//  SelectionToolbar.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SelectionToolbar: View {
  let selectedCount: Int
  let totalCount: Int
  let isDeleting: Bool
  let onSelectAll: () -> Void
  let onDelete: () -> Void
  let onCancel: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button {
        withAnimation {
          onSelectAll()
        }
      } label: {
        Label(
          selectedCount == totalCount ? "Deselect All" : "Select All",
          systemImage: selectedCount == totalCount
            ? "checkmark.circle.fill" : "checkmark.circle"
        )
        .font(.footnote)
      }
      .buttonStyle(.bordered)

      Button(role: .destructive) {
        if selectedCount > 0 {
          onDelete()
        }
      } label: {
        Label("Delete (\(selectedCount))", systemImage: "trash.fill")
          .font(.footnote)
      }
      .buttonStyle(.borderedProminent)
      .disabled(isDeleting || selectedCount == 0)
      .opacity(selectedCount == 0 ? 0 : 1)

      Spacer()

      Button(role: .cancel) {
        withAnimation {
          onCancel()
        }
      } label: {
        Label("Cancel", systemImage: "xmark.circle")
          .font(.footnote)
      }
      .buttonStyle(.bordered)
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
  }
}
