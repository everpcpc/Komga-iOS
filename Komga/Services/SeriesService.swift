//
//  SeriesService.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

class SeriesService {
  static let shared = SeriesService()
  private let apiClient = APIClient.shared

  private init() {}

  func getSeries(
    libraryId: String = "",
    page: Int = 0,
    size: Int = 20,
    sort: String = "metadata.titleSort,asc",
    readStatus: ReadStatusFilter? = nil,
    seriesStatus: SeriesStatusFilter? = nil
  ) async throws -> Page<Series> {
    var queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
      URLQueryItem(name: "sort", value: sort),
    ]

    if !libraryId.isEmpty {
      queryItems.append(URLQueryItem(name: "library_id", value: libraryId))
    }

    if let readStatus = readStatus, readStatus != .all {
      queryItems.append(URLQueryItem(name: "read_status", value: readStatus.rawValue))
    }

    if let seriesStatus = seriesStatus, seriesStatus != .all {
      queryItems.append(URLQueryItem(name: "metadata.status", value: seriesStatus.rawValue))
    }

    return try await apiClient.request(path: "/api/v1/series", queryItems: queryItems)
  }

  func getOneSeries(id: String) async throws -> Series {
    return try await apiClient.request(path: "/api/v1/series/\(id)")
  }

  func getNewSeries(
    libraryId: String = "",
    page: Int = 0,
    size: Int = 20
  ) async throws -> Page<Series> {
    var queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
    ]

    if !libraryId.isEmpty {
      queryItems.append(URLQueryItem(name: "library_id", value: libraryId))
    }

    return try await apiClient.request(path: "/api/v1/series/new", queryItems: queryItems)
  }

  func getUpdatedSeries(
    libraryId: String = "",
    page: Int = 0,
    size: Int = 20
  ) async throws -> Page<Series> {
    var queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
    ]

    if !libraryId.isEmpty {
      queryItems.append(URLQueryItem(name: "library_id", value: libraryId))
    }

    return try await apiClient.request(path: "/api/v1/series/updated", queryItems: queryItems)
  }

  func getSeriesThumbnail(id: String) async throws -> Data {
    return try await apiClient.requestData(path: "/api/v1/series/\(id)/thumbnail")
  }

  func markAsRead(seriesId: String) async throws {
    let _: EmptyResponse = try await apiClient.request(
      path: "/api/v1/series/\(seriesId)/read-progress",
      method: "POST"
    )
  }

  func markAsUnread(seriesId: String) async throws {
    let _: EmptyResponse = try await apiClient.request(
      path: "/api/v1/series/\(seriesId)/read-progress",
      method: "DELETE"
    )
  }
}
