//
//  PageJumpSheetView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct PageJumpSheetView: View {
  let totalPages: Int
  let currentPage: Int
  let onJump: (Int) -> Void

  @AppStorage("themeColorHex") private var themeColor: ThemeColor = .orange

  @Environment(\.dismiss) private var dismiss
  @State private var pageValue: Int

  private var maxPage: Int {
    max(totalPages, 1)
  }

  private var canJump: Bool {
    totalPages > 0
  }

  private var rangeDescription: String {
    canJump ? "Range: 1 – \(totalPages)" : "No pages available"
  }

  private var sliderBinding: Binding<Double> {
    Binding(
      get: { Double(pageValue) },
      set: { newValue in
        pageValue = Int(newValue.rounded())
      }
    )
  }

  init(totalPages: Int, currentPage: Int, onJump: @escaping (Int) -> Void) {
    self.totalPages = totalPages
    self.currentPage = currentPage
    self.onJump = onJump

    let safeInitialPage = max(1, min(currentPage, max(totalPages, 1)))
    _pageValue = State(initialValue: safeInitialPage)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        VStack(spacing: 8) {
          Text(rangeDescription)
            .font(.headline)
            .foregroundStyle(.secondary)
          if canJump {
            Text("Current page: \(currentPage)")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
        }

        if canJump {
          VStack(spacing: 20) {
            Text("Selected page: \(pageValue)")
              .font(.headline)

            VStack(spacing: 8) {
              Slider(
                value: sliderBinding,
                in: 1...Double(maxPage),
                step: 1
              )
              .tint(themeColor.color)

              HStack {
                Text("1")
                Spacer()
                Text("\(totalPages)")
              }
              .font(.footnote)
              .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer()
      }
      .padding()
      .navigationTitle("Go to Page")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            dismiss()
          } label: {
            Label("Close", systemImage: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            jumpToPage()
          } label: {
            Label("Jump", systemImage: "arrow.right.to.line")
          }
          .disabled(!canJump || pageValue == currentPage)
        }
      }
    }
  }

  private func jumpToPage() {
    guard canJump else { return }
    let clampedValue = min(max(pageValue, 1), totalPages)
    onJump(clampedValue)
    dismiss()
  }
}
