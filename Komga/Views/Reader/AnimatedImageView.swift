//
//  AnimatedImageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SDWebImageSwiftUI
import SwiftUI

/// A SwiftUI view that displays animated images (GIF, animated WebP) using SDWebImageSwiftUI
struct AnimatedImageView: View {
  let url: URL?
  let contentMode: ContentMode

  init(url: URL?, contentMode: ContentMode = .fit) {
    self.url = url
    self.contentMode = contentMode
  }

  var body: some View {
    if let url = url {
      // Use SDWebImage to load and display (handles both static and animated images)
      // Options:
      // - .retryFailed: Retry failed downloads
      // - .scaleDownLargeImages: Scale down large images to reduce memory usage
      // - .decodeFirstFrameOnly: For animated images, only decode first frame initially
      // - .avoidDecodeImage: Avoid automatic decoding to reduce memory (decode on-demand)
      AnimatedImage(
        url: url,
        options: [.retryFailed, .scaleDownLargeImages, .decodeFirstFrameOnly],
        context: [
          // Limit single image memory to 50MB (will scale down if larger)
          .imageScaleDownLimitBytes: 50 * 1024 * 1024
        ]
      )
      .resizable()
      .aspectRatio(contentMode: contentMode)
      .transition(.fade)
    } else {
      Color.clear
    }
  }
}
