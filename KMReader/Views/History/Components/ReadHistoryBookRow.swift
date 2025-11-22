//
//  ReadHistoryBookRow.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct ReadHistoryBookRow: View {
  let book: Book

  private var thumbnailURL: URL? {
    BookService.shared.getBookThumbnailURL(id: book.id)
  }

  var body: some View {
    HStack {
      // Thumbnail
      ThumbnailImage(url: thumbnailURL, width: 80, cornerRadius: 6)

      // Book info
      VStack(alignment: .leading, spacing: 6) {
        Text(book.seriesTitle)
          .font(.footnote)
          .foregroundColor(.secondary)
          .lineLimit(1)

        Text("#\(Int(book.number)) - \(book.metadata.title)")
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .lineLimit(2)

        Group {
          if book.deleted {
            Text("Unavailable")
              .foregroundColor(.red)
          } else {
            Text("\(book.media.pagesCount) pages")
              .foregroundColor(.secondary)
          }
        }.font(.caption)

        if let progress = book.readProgress {
          Text("Last read: \(formatRelativeDate(progress.readDate))")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private func formatRelativeDate(_ date: Date) -> String {
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

    if let days = components.day {
      if days == 0 {
        if let hours = components.hour {
          if hours == 0 {
            if let minutes = components.minute {
              return "\(minutes)m ago"
            }
          }
          return "\(hours)h ago"
        }
      } else if days == 1 {
        return "Yesterday"
      } else if days < 7 {
        return "\(days) days ago"
      }
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
