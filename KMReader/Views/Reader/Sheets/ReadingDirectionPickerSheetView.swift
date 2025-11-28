//
//  ReadingDirectionPickerSheetView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadingDirectionPickerSheetView: View {
  @Binding var readingDirection: ReadingDirection

  var body: some View {
    NavigationStack {
      List {
        Picker("", selection: $readingDirection) {
          ForEach(ReadingDirection.availableCases, id: \.self) { direction in
            HStack {
              Image(systemName: direction.icon)
              Text(direction.displayName)
            }.tag(direction)
          }
        }
        .pickerStyle(.inline)
        .buttonStyle(.plain)
      }
      .navigationTitle("Reading Direction")
      #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }
}
