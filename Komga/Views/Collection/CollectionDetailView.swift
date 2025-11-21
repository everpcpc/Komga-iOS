//
//  CollectionDetailView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct CollectionDetailView: View {
  let collectionId: String

  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  @Environment(\.dismiss) private var dismiss

  @State private var seriesViewModel = SeriesViewModel()
  @State private var collection: Collection?
  @State private var actionErrorMessage: String?
  @State private var showDeleteConfirmation = false

  private var thumbnailURL: URL? {
    collection.flatMap { CollectionService.shared.getCollectionThumbnailURL(id: $0.id) }
  }

  private var isActionErrorPresented: Binding<Bool> {
    Binding(
      get: { actionErrorMessage != nil },
      set: { if !$0 { actionErrorMessage = nil } }
    )
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        if let collection = collection {
          // Header with thumbnail and info
          HStack(alignment: .top, spacing: 16) {
            ThumbnailImage(url: thumbnailURL, showPlaceholder: false, width: 120)

            VStack(alignment: .leading) {
              Text(collection.name)
                .font(.title2)

              // Series count
              Text("\(collection.seriesIds.count) series")
                .font(.caption)
                .foregroundColor(.secondary)

              // Created date
              HStack(spacing: 4) {
                Image(systemName: "calendar.badge.plus")
                  .font(.caption2)
                Text(collection.createdDate.formatted(date: .abbreviated, time: .omitted))
              }
              .font(.caption)
              .foregroundColor(.secondary)

              // Last modified date
              HStack(spacing: 4) {
                Image(systemName: "clock")
                  .font(.caption2)
                Text(collection.lastModifiedDate.formatted(date: .abbreviated, time: .omitted))
              }
              .font(.caption)
              .foregroundColor(.secondary)

              // Ordered indicator
              if collection.ordered {
                HStack(spacing: 4) {
                  Image(systemName: "arrow.up.arrow.down")
                    .font(.caption2)
                  Text("Ordered")
                }
                .font(.caption)
                .foregroundColor(.secondary)
              }
            }

            Spacer()
          }

          // Series list
          SeriesListView(
            collectionId: collectionId,
            seriesViewModel: seriesViewModel
          )
        } else {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .padding(.horizontal)
    }
    .navigationTitle("Collection")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Action Failed", isPresented: isActionErrorPresented) {
      Button("OK", role: .cancel) {}
    } message: {
      if let actionErrorMessage {
        Text(actionErrorMessage)
      }
    }
    .alert("Delete Collection?", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        Task {
          await deleteCollection()
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will permanently delete \(collection?.name ?? "this collection") from Komga.")
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button(role: .destructive) {
            showDeleteConfirmation = true
          } label: {
            Label("Delete Collection", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .task {
      await loadCollectionDetails()
    }
  }
}

// Helper functions for CollectionDetailView
extension CollectionDetailView {
  private func loadCollectionDetails() async {
    do {
      collection = try await CollectionService.shared.getCollection(id: collectionId)
    } catch {
      actionErrorMessage = error.localizedDescription
    }
  }

  @MainActor
  private func deleteCollection() async {
    do {
      try await CollectionService.shared.deleteCollection(collectionId: collectionId)
      dismiss()
    } catch {
      actionErrorMessage = error.localizedDescription
    }
  }
}

// Series list view for collection
struct SeriesListView: View {
  let collectionId: String
  @Bindable var seriesViewModel: SeriesViewModel

  @AppStorage("collectionSeriesBrowseOptions") private var browseOpts: SeriesBrowseOptions =
    SeriesBrowseOptions()

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Series")
          .font(.headline)

        Spacer()

        SeriesFilterView(browseOpts: $browseOpts)
      }

      if seriesViewModel.isLoading && seriesViewModel.series.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        LazyVStack(spacing: 8) {
          ForEach(seriesViewModel.series) { series in
            NavigationLink(value: NavDestination.seriesDetail(seriesId: series.id)) {
              SeriesRowView(
                series: series,
                onActionCompleted: {
                  Task {
                    await seriesViewModel.loadCollectionSeries(
                      collectionId: collectionId, browseOpts: browseOpts, refresh: true)
                  }
                }
              )
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(role: .destructive) {
                Task {
                  do {
                    try await CollectionService.shared.removeSeriesFromCollection(
                      collectionId: collectionId, seriesId: series.id)
                    await seriesViewModel.loadCollectionSeries(
                      collectionId: collectionId, browseOpts: browseOpts, refresh: true)
                  } catch {
                  }
                }
              } label: {
                Label("Remove", systemImage: "trash")
              }
            }
            .onAppear {
              if series.id == seriesViewModel.series.last?.id {
                Task {
                  await seriesViewModel.loadCollectionSeries(
                    collectionId: collectionId, browseOpts: browseOpts, refresh: false)
                }
              }
            }
          }

          if seriesViewModel.isLoading && !seriesViewModel.series.isEmpty {
            ProgressView()
              .frame(maxWidth: .infinity)
              .padding()
          }
        }
      }
    }
    .task(id: collectionId) {
      await seriesViewModel.loadCollectionSeries(
        collectionId: collectionId, browseOpts: browseOpts, refresh: true)
    }
    .onChange(of: browseOpts) {
      Task {
        await seriesViewModel.loadCollectionSeries(
          collectionId: collectionId, browseOpts: browseOpts, refresh: true)
      }
    }
  }
}
