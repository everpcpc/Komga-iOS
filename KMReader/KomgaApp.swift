//
//  KomgaApp.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SDWebImage
import SDWebImageWebPCoder
import SwiftData
import SwiftUI

@main
struct KomgaApp: App {
  private let modelContainer: ModelContainer
  @State private var authViewModel: AuthViewModel

  init() {
    do {
      modelContainer = try ModelContainer(for: KomgaInstance.self, KomgaLibrary.self)
    } catch {
      fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
    }
    KomgaInstanceStore.shared.configure(with: modelContainer)
    KomgaLibraryStore.shared.configure(with: modelContainer)
    _authViewModel = State(initialValue: AuthViewModel())
    configureSDWebImage()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(authViewModel)
        .modelContainer(modelContainer)
        .onChange(of: authViewModel.isLoggedIn) {
          configureSDWebImage()
        }
        .onChange(of: authViewModel.credentialsVersion) {
          configureSDWebImage()
        }
    }
    #if canImport(AppKit)
      WindowGroup("Reader", id: "reader") {
        ReaderWindowView()
          .environment(authViewModel)
          .modelContainer(modelContainer)
      }
      .defaultSize(width: 1200, height: 800)
    #endif
  }

  private func configureSDWebImage() {
    // Set authentication header for SDWebImage
    if let authToken = AppConfig.authToken {
      SDWebImageDownloader.shared.setValue(
        "Basic \(authToken)", forHTTPHeaderField: "Authorization")
    } else {
      SDWebImageDownloader.shared.setValue(nil, forHTTPHeaderField: "Authorization")
    }

    // Register WebP coder
    SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
  }
}
