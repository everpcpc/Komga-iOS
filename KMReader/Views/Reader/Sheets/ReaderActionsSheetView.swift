//
//  ReaderActionsSheetView.swift
//  KMReader
//
//  Created by Komga iOS Client
//

import SwiftUI

enum ReaderActionsSheetAction {
  case readingDirection
  case jumpToPage
  case toc
  case cancel
}

struct ReaderActionsSheetView: View {
  let hasTOC: Bool
  let readingDirectionIcon: String
  let onSelectAction: (ReaderActionsSheetAction) -> Void

  var body: some View {
    NavigationStack {
      List {
        Button {
          onSelectAction(.readingDirection)
        } label: {
          HStack {
            Image(systemName: readingDirectionIcon)
            Text("Reading Direction")
          }
        }

        Button {
          onSelectAction(.jumpToPage)
        } label: {
          HStack {
            Image(systemName: "square.and.arrow.down")
            Text("Jump to Page")
          }
        }

        if hasTOC {
          Button {
            onSelectAction(.toc)
          } label: {
            HStack {
              Image(systemName: "list.bullet.rectangle")
              Text("Table of Contents")
            }
          }
        }
      }
      .buttonStyle(.plain)
      .navigationTitle("More Actions")
      #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
}
