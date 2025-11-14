//
//  SeriesViewModel.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

@MainActor
@Observable
class SeriesViewModel {
  var series: [Series] = []
  var isLoading = false
  var errorMessage: String?
  var thumbnailCache: [String: UIImage] = [:]

  private let seriesService = SeriesService.shared
  private var currentPage = 0
  private var hasMorePages = true

  func loadSeries(libraryId: String = "", refresh: Bool = false) async {
    if refresh {
      currentPage = 0
      series = []
      hasMorePages = true
    }

    guard hasMorePages && !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      let page = try await seriesService.getSeries(
        libraryId: libraryId,
        page: currentPage,
        size: 20
      )

      series.append(contentsOf: page.content)
      hasMorePages = !page.last
      currentPage += 1
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadNewSeries(libraryId: String = "") async {
    isLoading = true
    errorMessage = nil

    do {
      let page = try await seriesService.getNewSeries(libraryId: libraryId, size: 20)
      series = page.content
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadUpdatedSeries(libraryId: String = "") async {
    isLoading = true
    errorMessage = nil

    do {
      let page = try await seriesService.getUpdatedSeries(libraryId: libraryId, size: 20)
      series = page.content
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadThumbnail(for seriesId: String) async -> UIImage? {
    if let cached = thumbnailCache[seriesId] {
      return cached
    }

    do {
      let data = try await seriesService.getSeriesThumbnail(id: seriesId)
      if let image = UIImage(data: data) {
        thumbnailCache[seriesId] = image
        return image
      }
    } catch {
      // Silently fail for thumbnails
    }

    return nil
  }

  func markAsRead(seriesId: String) async {
    do {
      try await seriesService.markAsRead(seriesId: seriesId)
      await loadSeries(refresh: true)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func markAsUnread(seriesId: String) async {
    do {
      try await seriesService.markAsUnread(seriesId: seriesId)
      await loadSeries(refresh: true)
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
