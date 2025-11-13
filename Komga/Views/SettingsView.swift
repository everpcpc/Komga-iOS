//
//  ContentView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SettingsView: View {
  @Environment(AuthViewModel.self) private var authViewModel
  @AppStorage("webtoonPageWidthPercentage") private var webtoonPageWidthPercentage: Double = 100.0

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Account")) {
          if let user = authViewModel.user {
            HStack {
              Text("Email")
              Spacer()
              Text(user.email)
                .foregroundColor(.secondary)
            }
          }
        }

        Section(header: Text("Reader")) {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Pillarbox / Horizontal Padding")
              Spacer()
              Text("\(Int(webtoonPageWidthPercentage))%")
                .foregroundColor(.secondary)
            }
            Slider(
              value: $webtoonPageWidthPercentage,
              in: 50...100,
              step: 5
            )
            Text("For webtoon reading, adjust the width of pages as a percentage of screen width")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Section {
          Button(role: .destructive) {
            authViewModel.logout()
          } label: {
            HStack {
              Spacer()
              Text("Logout")
              Spacer()
            }
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
