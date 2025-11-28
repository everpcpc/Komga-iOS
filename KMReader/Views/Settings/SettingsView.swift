//
//  SettingsView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SettingsView: View {
  @Environment(AuthViewModel.self) private var authViewModel

  var body: some View {
    NavigationStack {
      List {
        Section {
          NavigationLink(value: NavDestination.settingsAppearance) {
            Label("Appearance", systemImage: "paintbrush")
          }
          NavigationLink(value: NavDestination.settingsCache) {
            Label("Cache", systemImage: "externaldrive")
          }
          NavigationLink(value: NavDestination.settingsReader) {
            Label("Reader", systemImage: "book.pages")
          }
        }

        Section(header: Text("Management")) {
          NavigationLink(value: NavDestination.settingsLibraries) {
            Label("Libraries", systemImage: "books.vertical")
          }
          NavigationLink(value: NavDestination.settingsServerInfo) {
            Label("Server Info", systemImage: "server.rack")
          }
          .disabled(!AppConfig.isAdmin)
          NavigationLink(value: NavDestination.settingsMetrics) {
            Label("Metrics", systemImage: "chart.bar")
          }
          .disabled(!AppConfig.isAdmin)
        }

        Section(header: Text("Account")) {
          NavigationLink(value: NavDestination.settingsServers) {
            HStack {
              Label("Servers", systemImage: "list.bullet.rectangle")
              if let displayName = AppConfig.serverDisplayName, !displayName.isEmpty {
                Spacer()
                Text(displayName)
                  .lineLimit(1)
                  .foregroundColor(.secondary)
              }
            }
          }
          if let user = authViewModel.user {
            HStack {
              Label("User", systemImage: "person")
              Spacer()
              Text(user.email)
                .lineLimit(1)
                .foregroundColor(.secondary)
            }
            HStack {
              Label("Role", systemImage: "shield")
              Spacer()
              Text(AppConfig.isAdmin ? "Admin" : "User")
                .lineLimit(1)
                .foregroundColor(.secondary)
            }
          }
          NavigationLink(value: NavDestination.settingsAuthenticationActivity) {
            Label("Authentication Activity", systemImage: "clock")
          }
        }

        HStack {
          Spacer()
          Text(appVersion).foregroundColor(.secondary)
          Spacer()
        }
      }

      .handleNavigation()
      .navigationTitle("Settings")
      #if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    return "v\(version) (build \(build))"
  }
}
