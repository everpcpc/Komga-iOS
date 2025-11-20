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
      Form {
        Section(header: Text("Account")) {
          if let user = authViewModel.user {
            HStack {
              Label("Email", systemImage: "envelope")
              Spacer()
              Text(user.email)
                .foregroundColor(.secondary)
            }
            HStack {
              Label("Roles", systemImage: "person.2")
              Spacer()
              Text(user.roles.joined(separator: ", "))
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.secondary)
            }
          }
        }

        Section {
          NavigationLink(value: NavDestination.settingsLibraries) {
            Label("Library Management", systemImage: "books.vertical")
          }
        }

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

        Section {
          Button(role: .destructive) {
            authViewModel.logout()
          } label: {
            HStack {
              Spacer()
              Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
              Spacer()
            }
          }
        }
      }
      .handleNavigation()
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
