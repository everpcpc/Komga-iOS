//
//  BrowseView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BrowseView: View {
  @AppStorage("selectedLibraryId") private var selectedLibraryId: String = ""
  @State private var browseOpts = BrowseOptions()
  @State private var showBrowseOptionsSheet = false

  private var selectedLibrary: LibraryInfo? {
    guard !selectedLibraryId.isEmpty else { return nil }
    return LibraryManager.shared.getLibrary(id: selectedLibraryId)
  }

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
        ScrollView {
          VStack(spacing: 0) {
            // Library Selector
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
            .padding(.vertical)

            SeriesListView(
              browseOpts: browseOpts,
              width: geometry.size.width
            )
            .id(
              "\(browseOpts.readStatusFilter)-\(browseOpts.seriesStatusFilter)-\(browseOpts.sortField)-\(browseOpts.sortDirection)"
            )
          }
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              showBrowseOptionsSheet = true
            } label: {
              Image(systemName: "line.3.horizontal.decrease.circle")
            }
          }
        }
        .sheet(isPresented: $showBrowseOptionsSheet) {
          BrowseOptionsSheet(browseOpts: browseOpts)
        }
        .onChange(of: selectedLibraryId) {
          browseOpts.libraryId = selectedLibraryId
        }
        .onAppear {
          browseOpts.libraryId = selectedLibraryId
        }
      }
    }
  }
}

struct BrowseOptionsSheet: View {
  @Bindable var browseOpts: BrowseOptions
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        // Filter Section
        Section("Filters") {
          // Read Status Filter
          Picker("Read Status", selection: $browseOpts.readStatusFilter) {
            ForEach(ReadStatusFilter.allCases, id: \.self) { filter in
              Text(filter.displayName).tag(filter)
            }
          }
          .pickerStyle(.menu)

          // Series Status Filter
          Picker("Series Status", selection: $browseOpts.seriesStatusFilter) {
            ForEach(SeriesStatusFilter.allCases, id: \.self) { filter in
              Text(filter.displayName).tag(filter)
            }
          }
          .pickerStyle(.menu)
        }

        // Sort Section
        Section("Sort") {
          // Sort Field
          Picker("Sort By", selection: $browseOpts.sortField) {
            ForEach(SeriesSortField.allCases, id: \.self) { field in
              Text(field.displayName).tag(field)
            }
          }
          .pickerStyle(.menu)

          // Sort Direction (only show if field supports direction)
          if browseOpts.sortField.supportsDirection {
            Picker("Direction", selection: $browseOpts.sortDirection) {
              ForEach(SortDirection.allCases, id: \.self) { direction in
                HStack {
                  Image(systemName: direction.icon)
                  Text(direction.displayName)
                }
                .tag(direction)
              }
            }
            .pickerStyle(.menu)
          }
        }
      }
      .navigationTitle("Filter & Sort")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}
