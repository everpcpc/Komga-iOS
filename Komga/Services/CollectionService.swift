//
//  CollectionService.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

class CollectionService {
  static let shared = CollectionService()
  private let apiClient = APIClient.shared

  private init() {}

  func getCollections(
    libraryId: String = "",
    page: Int = 0,
    size: Int = 20
  ) async throws -> Page<Collection> {
    var queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
    ]

    if !libraryId.isEmpty {
      queryItems.append(URLQueryItem(name: "library_id", value: libraryId))
    }

    return try await apiClient.request(path: "/api/v1/collections", queryItems: queryItems)
  }

  func getCollection(id: String) async throws -> Collection {
    return try await apiClient.request(path: "/api/v1/collections/\(id)")
  }
}
