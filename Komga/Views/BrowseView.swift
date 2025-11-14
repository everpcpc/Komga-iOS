//
//  BrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BrowseView: View {
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  private var selectedLibrary: LibraryInfo? {
    guard !selectedLibraryId.isEmpty else { return nil }
    return LibraryManager.shared.getLibrary(id: selectedLibraryId)
  }

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        ScrollView {
          VStack {
            HStack {
              Menu {
                Picker(selection: $selectedLibraryId) {
                  Label("All Libraries", systemImage: "square.grid.2x2").tag("")
                  ForEach(LibraryManager.shared.libraries) { library in
                    Label(library.name, systemImage: "books.vertical").tag(library.id)
                  }
                } label: {
                  Label(
                    selectedLibrary?.name ?? "All Libraries",
                    systemImage: selectedLibraryId.isEmpty ? "square.grid.2x2" : "books.vertical")
                }
                .pickerStyle(.inline)
              } label: {
                HStack {
                  Image(
                    systemName: selectedLibraryId.isEmpty ? "square.grid.2x2" : "books.vertical")
                  Text(selectedLibrary?.name ?? "All Libraries")
                    .font(.body)
                  Image(systemName: "chevron.down")
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
              }
              Spacer()
            }
            .padding(.horizontal)

            SeriesListView(libraryId: selectedLibraryId, width: geometry.size.width)
          }
          .padding(.vertical)
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: selectedLibraryId)
      }
    }
  }
}
