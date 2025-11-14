//
//  ReadListService.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

class ReadListService {
  static let shared = ReadListService()
  private let apiClient = APIClient.shared

  private init() {}

  func getReadLists(
    libraryId: String = "",
    page: Int = 0,
    size: Int = 20
  ) async throws -> Page<ReadList> {
    var queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
    ]

    if !libraryId.isEmpty {
      queryItems.append(URLQueryItem(name: "library_id", value: libraryId))
    }

    return try await apiClient.request(path: "/api/v1/readlists", queryItems: queryItems)
  }

  func getReadList(id: String) async throws -> ReadList {
    return try await apiClient.request(path: "/api/v1/readlists/\(id)")
  }
}
