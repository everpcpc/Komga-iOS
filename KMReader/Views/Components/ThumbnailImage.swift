//
//  ThumbnailImage.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

/// A reusable thumbnail image component using SDWebImageSwiftUI
struct ThumbnailImage<Overlay: View>: View {
  let url: URL?
  let showPlaceholder: Bool
  let width: CGFloat
  let cornerRadius: CGFloat
  let overlay: (() -> Overlay)?

  @AppStorage("thumbnailPreserveAspectRatio") private var thumbnailPreserveAspectRatio: Bool = true

  init(
    url: URL?,
    showPlaceholder: Bool = true,
    width: CGFloat,
    cornerRadius: CGFloat = 8,
    @ViewBuilder overlay: @escaping () -> Overlay
  ) {
    self.url = url
    self.showPlaceholder = showPlaceholder
    self.width = width
    self.cornerRadius = cornerRadius
    self.overlay = overlay
  }

  private var contentMode: ContentMode {
    if thumbnailPreserveAspectRatio {
      return .fit
    } else {
      return .fill
    }
  }

  var body: some View {
    ZStack {
      // Background container with rounded corners
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(Color.clear)
        .frame(width: width, height: width * 1.3)

      // Image content - this will be the target for overlay alignment
      // When contentMode is .fit, the image may not fill the entire container,
      // so we need to ensure overlay aligns to the actual image bounds
      if let url = url {
        WebImage(
          url: url,
          options: [.retryFailed, .scaleDownLargeImages],
          context: [.customManager: SDImageCacheProvider.thumbnailManager]
        )
        .resizable()
        .placeholder {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
              if showPlaceholder {
                ProgressView()
              }
            }
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.25))
        .aspectRatio(contentMode: contentMode)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(alignment: .topTrailing) {
          if let overlay = overlay {
            overlay()
          } else {
            EmptyView()
          }
        }
        .frame(width: width, height: width * 1.3, alignment: .center)
      } else {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.gray.opacity(0.3))
          .frame(width: width, height: width * 1.3, alignment: .center)
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
          .overlay {
            if showPlaceholder {
              ProgressView()
            }
          }
      }
    }
    .frame(width: width, height: width * 1.3)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .shadow(color: Color.black.opacity(0.5), radius: 4)
  }
}

extension ThumbnailImage where Overlay == EmptyView {
  init(
    url: URL?,
    showPlaceholder: Bool = true,
    width: CGFloat,
    cornerRadius: CGFloat = 8
  ) {
    self.init(
      url: url, showPlaceholder: showPlaceholder,
      width: width, cornerRadius: cornerRadius
    ) {}
  }
}
