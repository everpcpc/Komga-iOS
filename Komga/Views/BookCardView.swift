//
//  BookCardView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct BookCardView: View {
  let book: Book
  var viewModel: BookViewModel
  let cardWidth: CGFloat
  @State private var thumbnail: UIImage?
  @AppStorage("themeColorName") private var themeColorOption: ThemeColorOption = .orange

  private var progress: Double {
    guard let readProgress = book.readProgress else { return 0 }
    guard book.media.pagesCount > 0 else { return 0 }
    return Double(readProgress.page) / Double(book.media.pagesCount)
  }

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
        if book.readProgress == nil {
          Circle()
            .fill(themeColorOption.color)
            .frame(width: 12, height: 12)
            .padding(4)
        }
      }
      .overlay(alignment: .bottom) {
        if book.readProgress != nil {
          GeometryReader { geometry in
            ZStack(alignment: .leading) {
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 4)
                .cornerRadius(2)

              Rectangle()
                .fill(themeColorOption.color)
                .frame(width: geometry.size.width * progress, height: 4)
                .cornerRadius(2)
            }
          }
          .frame(height: 4)
          .padding(.horizontal, 4)
          .padding(.bottom, 4)
        }
      }

      // Book info
      VStack(alignment: .leading, spacing: 2) {
        // Series title
        Text(book.seriesTitle)
          .font(.caption)
          .foregroundColor(.primary)
          .lineLimit(1)

        // Book number - Book title
        Text("\(book.metadata.number) - \(book.metadata.title)")
          .font(.caption)
          .foregroundColor(.primary)
          .lineLimit(1)

        // Pages count and file size
        Text("\(book.media.pagesCount) pages · \(book.size)")
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }
      .frame(width: cardWidth, alignment: .leading)
    }
    .animation(.default, value: thumbnail)
    .task {
      thumbnail = await viewModel.loadThumbnail(for: book.id)
    }
  }
}
