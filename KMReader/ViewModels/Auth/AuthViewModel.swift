//
//  AuthViewModel.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AuthViewModel {
  var isLoggedIn = false
  var isLoading = false
  var user: User?

  private let authService = AuthService.shared

  init() {
    self.isLoggedIn = authService.isLoggedIn()
  }

  func login(username: String, password: String, serverURL: String) async {
    isLoading = true

    do {
      user = try await authService.login(
        username: username, password: password, serverURL: serverURL)
      isLoggedIn = true
    } catch {
      ErrorManager.shared.alert(error: error)
      isLoggedIn = false
    }

    isLoading = false
  }

  func logout() {
    Task {
      try? await authService.logout()
    }
    isLoggedIn = false
    user = nil
  }

  func loadCurrentUser() async {
    do {
      user = try await authService.getCurrentUser()
      if let user = user {
        AppConfig.isAdmin = user.roles.contains("ADMIN")
      }
    } catch {
      // Don't show alert for unauthorized errors during background refresh
      if let apiError = error as? APIError, case .unauthorized = apiError {
        // Silently handle unauthorized during background refresh
        return
      }
      ErrorManager.shared.alert(error: error)
    }
  }
}
