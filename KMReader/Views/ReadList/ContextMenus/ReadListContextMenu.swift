//
//  ReadListContextMenu.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

@MainActor
struct ReadListContextMenu: View {
  let readList: ReadList
  var onActionCompleted: (() -> Void)? = nil
  var onDeleteRequested: (() -> Void)? = nil
  var onEditRequested: (() -> Void)? = nil

  var body: some View {
    Group {
      NavigationLink(value: NavDestination.readListDetail(readListId: readList.id)) {
        Label("View Details", systemImage: "info.circle")
      }

      Divider()

      Button {
        onEditRequested?()
      } label: {
        Label("Edit", systemImage: "pencil")
      }
      .disabled(!AppConfig.isAdmin)

      Divider()

      Button(role: .destructive) {
        onDeleteRequested?()
      } label: {
        Label("Delete", systemImage: "trash")
      }
      .disabled(!AppConfig.isAdmin)
    }
  }
}
