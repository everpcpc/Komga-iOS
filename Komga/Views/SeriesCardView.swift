//
//  SeriesCardView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct SeriesCardView: View {
  let series: Series
  var viewModel: SeriesViewModel
  let cardWidth: CGFloat
  @State private var thumbnail: UIImage?
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Thumbnail
      ZStack {
        if let thumbnail = thumbnail {
          Image(uiImage: thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
              ProgressView()
            }
        }
      }
      .frame(width: cardWidth, height: cardWidth * 1.3)
      .clipped()
      .cornerRadius(8)
      .overlay(alignment: .topTrailing) {
        if series.booksUnreadCount > 0 {
          Text("\(series.booksUnreadCount)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(themeColorOption.color)
            .clipShape(Capsule())
            .padding(4)
        }
      }

      // Series info
      VStack(alignment: .leading, spacing: 2) {
        Text(series.metadata.title)
          .font(.caption)
          .foregroundColor(.primary)
          .lineLimit(1)

        Text("\(series.booksCount) books")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      .frame(width: cardWidth, alignment: .leading)
    }
    .animation(.default, value: thumbnail)
    .task {
      thumbnail = await viewModel.loadThumbnail(for: series.id)
    }
  }
}
