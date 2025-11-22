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

  var selectAllLabel: String {
    selectedCount == totalCount ? "Deselect All" : "Select All"
  }

  var selectAllImage: String {
    selectedCount == totalCount ? "checkmark.circle.fill" : "checkmark.circle"
  }

  var deleteLabel: String {
    selectedCount == 0 ? "Delete" : "Delete (\(selectedCount))"
  }

  var submitDisabled: Bool {
    isDeleting || selectedCount == 0 || selectedCount == totalCount
  }

  var body: some View {
    HStack {
      Button {
        withAnimation {
          onSelectAll()
        }
      } label: {
        Label(selectAllLabel, systemImage: selectAllImage)
          .font(.footnote)
      }
      .buttonStyle(.bordered)

      Button(role: .destructive) {
        if selectedCount > 0 {
          onDelete()
        }
      } label: {
        Label(deleteLabel, systemImage: "trash.fill")
          .font(.footnote)
      }
      .buttonStyle(.borderedProminent)
      .disabled(submitDisabled)
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
