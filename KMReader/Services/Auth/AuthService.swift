//
//  AuthService.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import OSLog

class AuthService {
  static let shared = AuthService()
  private let apiClient = APIClient.shared
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "KMReader", category: "Auth")

  private init() {}

  func login(username: String, password: String, serverURL: String, rememberMe: Bool = true)
    async throws -> (user: User, authToken: String)
  {
    // Create basic auth token
    let credentials = "\(username):\(password)"
    guard let credentialsData = credentials.data(using: .utf8) else {
      throw APIError.invalidURL
    }
    let base64Credentials = credentialsData.base64EncodedString()

    // Validate login using validate method (reuses validation logic)
    let queryItems = [URLQueryItem(name: "remember-me", value: rememberMe ? "true" : "false")]
    let user = try await validate(
      serverURL: serverURL,
      authToken: base64Credentials,
      queryItems: queryItems
    )

    return (user: user, authToken: base64Credentials)
  }

  func logout() async throws {
    // Call logout API
    do {
      let _: EmptyResponse = try await apiClient.request(path: "/api/logout", method: "POST")
    } catch {
      // Continue even if logout API fails
    }

    // Clear local data
    apiClient.setAuthToken("")
    AppConfig.clearAuthData()

    // Clear library data
    LibraryManager.shared.clearAllLibraries()
  }

  func validate(serverURL: String, authToken: String, queryItems: [URLQueryItem]? = nil)
    async throws -> User
  {
    // Validate existing auth token using temporary request
    logger.info("📡 Validating server connection to \(serverURL)")
    let user: User = try await apiClient.requestTemporary(
      serverURL: serverURL,
      path: "/api/v2/users/me",
      method: "GET",
      authToken: authToken,
      queryItems: queryItems
    )
    logger.info("✅ Server validation successful")
    return user
  }

  func getCurrentUser() async throws -> User {
    return try await apiClient.request(path: "/api/v2/users/me")
  }

  func getAuthenticationActivity(page: Int = 0, size: Int = 20) async throws -> Page<
    AuthenticationActivity
  > {
    let queryItems = [
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "size", value: "\(size)"),
    ]
    return try await apiClient.request(
      path: "/api/v2/users/me/authentication-activity",
      queryItems: queryItems
    )
  }
}
