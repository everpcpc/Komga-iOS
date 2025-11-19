//
//  SeriesCardView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

@MainActor
struct SeriesContextMenu: View {
  let series: Series
  var onActionCompleted: (() -> Void)?
  var onActionFailed: ((String) -> Void)?

  private var canMarkAsRead: Bool {
    series.booksUnreadCount > 0
  }

  private var canMarkAsUnread: Bool {
    (series.booksReadCount + series.booksInProgressCount) > 0
  }

  var body: some View {
    Group {
      Button {
        analyzeSeries()
      } label: {
        Label("Analyze", systemImage: "waveform.path.ecg")
      }

      Button {
        refreshMetadata()
      } label: {
        Label("Refresh Metadata", systemImage: "arrow.clockwise")
      }

      Divider()

      if canMarkAsRead {
        Button {
          markSeriesAsRead()
        } label: {
          Label("Mark as Read", systemImage: "checkmark.circle")
        }
      }

      if canMarkAsUnread {
        Button {
          markSeriesAsUnread()
        } label: {
          Label("Mark as Unread", systemImage: "circle")
        }
      }
    }
  }

  private func analyzeSeries() {
    Task {
      do {
        try await SeriesService.shared.analyzeSeries(seriesId: series.id)
        await MainActor.run {
          onActionCompleted?()
        }
      } catch {
        await MainActor.run {
          onActionFailed?(error.localizedDescription)
        }
      }
    }
  }

  private func refreshMetadata() {
    Task {
      do {
        try await SeriesService.shared.refreshMetadata(seriesId: series.id)
        await MainActor.run {
          onActionCompleted?()
        }
      } catch {
        await MainActor.run {
          onActionFailed?(error.localizedDescription)
        }
      }
    }
  }

  private func markSeriesAsRead() {
    Task {
      do {
        try await SeriesService.shared.markAsRead(seriesId: series.id)
        await MainActor.run {
          onActionCompleted?()
        }
      } catch {
        await MainActor.run {
          onActionFailed?(error.localizedDescription)
        }
      }
    }
  }

  private func markSeriesAsUnread() {
    Task {
      do {
        try await SeriesService.shared.markAsUnread(seriesId: series.id)
        await MainActor.run {
          onActionCompleted?()
        }
      } catch {
        await MainActor.run {
          onActionFailed?(error.localizedDescription)
        }
      }
    }
  }
}

struct SeriesCardView: View {
  let series: Series
  let cardWidth: CGFloat
  let showTitle: Bool
  var onActionCompleted: (() -> Void)? = nil
  @State private var actionErrorMessage: String?

  private var isActionErrorPresented: Binding<Bool> {
    Binding(
      get: { actionErrorMessage != nil },
      set: { if !$0 { actionErrorMessage = nil } }
    )
  }

  private var thumbnailURL: URL? {
    SeriesService.shared.getSeriesThumbnailURL(id: series.id)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ThumbnailImage(url: thumbnailURL, width: cardWidth)
        .overlay(alignment: .topTrailing) {
          if series.booksUnreadCount > 0 {
            UnreadCountBadge(count: series.booksUnreadCount)
              .padding(4)
          }
        }

      VStack(alignment: .leading, spacing: 2) {
        if showTitle {
          Text(series.metadata.title)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(1)
        }
        Group {
          if series.deleted {
            Text("Unavailable")
              .foregroundColor(.red)
          } else {
            Text("\(series.booksCount) books")
              .foregroundColor(.secondary)
          }
        }.font(.caption2)
      }
      .frame(width: cardWidth, alignment: .leading)
    }
    .contentShape(Rectangle())
    .contextMenu {
      SeriesContextMenu(
        series: series,
        onActionCompleted: onActionCompleted,
        onActionFailed: { message in
          actionErrorMessage = message
        }
      )
    }
    .alert("Action Failed", isPresented: isActionErrorPresented) {
      Button("OK", role: .cancel) {}
    } message: {
      if let message = actionErrorMessage {
        Text(message)
      }
    }
  }
}
