//
//  ReaderWindowView.swift
//  Komga
//
//  Created by Komga iOS Client
//

#if canImport(AppKit)
  import SwiftUI
  import AppKit

  struct ReaderWindowView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var readerState: BookReaderState?

    var body: some View {
      Group {
        if let state = readerState, let book = state.book {
          BookReaderView(book: book, incognito: state.incognito)
            .id("\(book.id)-\(state.incognito)")
        } else {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
      .onAppear {
        // Get reader state from shared manager when view appears
        readerState = ReaderWindowManager.shared.currentState

        // If state is nil (e.g., app restarted and window was restored), close the window immediately
        if ReaderWindowManager.shared.currentState == nil {
          ReaderWindowManager.shared.isWindowOpen = false
          // Close window immediately without delay
          dismissWindow(id: "reader")
        } else {
          // Mark window as open only if we have valid state
          ReaderWindowManager.shared.isWindowOpen = true
        }
      }
      .onChange(of: ReaderWindowManager.shared.currentState) { oldState, newState in
        // Update reader state when manager state changes
        readerState = newState

        // If state is set to nil, dismiss the window
        if newState == nil {
          // Delay dismissal slightly to allow window to respond
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismissWindow(id: "reader")
          }
        }
      }
      .onDisappear {
        // Mark window as closed
        ReaderWindowManager.shared.isWindowOpen = false
        // Always clean up state when window disappears
        // This ensures the window can be reopened even if it was manually closed
        ReaderWindowManager.shared.closeReader()
      }
    }
  }

#endif
