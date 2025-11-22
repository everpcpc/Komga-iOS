//
//  ContentView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ContentView: View {
  @Environment(AuthViewModel.self) private var authViewModel
  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  var body: some View {
    Group {
      if authViewModel.isLoggedIn {
        MainTabView()
      } else {
        LoginView()
      }
    }
    .tint(themeColor.color)
    .task {
      if authViewModel.isLoggedIn {
        await authViewModel.loadCurrentUser()
        await LibraryManager.shared.loadLibraries()
      }
    }
    .onChange(of: authViewModel.isLoggedIn) { _, isLoggedIn in
      if isLoggedIn {
        Task {
          await authViewModel.loadCurrentUser()
          await LibraryManager.shared.loadLibraries()
        }
      }
    }
  }
}

struct MainTabView: View {
  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  var body: some View {
    TabView {
      DashboardView()
        .tabItem {
          Label("Home", systemImage: "house")
        }

      BrowseView()
        .tabItem {
          Label("Browse", systemImage: "books.vertical")
        }

      HistoryView()
        .tabItem {
          Label("History", systemImage: "clock")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
    .tint(themeColor.color)
  }
}
