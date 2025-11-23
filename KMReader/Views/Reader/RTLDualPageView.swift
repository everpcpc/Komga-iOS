//
//  RTLDualPageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct RTLDualPageView: View {
  @Bindable var viewModel: ReaderViewModel
  let rightPageIndex: Int?
  let leftPageIndex: Int
  let screenSize: CGSize

  @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .system

  var body: some View {
    HStack(spacing: 0) {
      // Right page (for RTL, right page is on the left side of screen)
      if let rightPageIndex = rightPageIndex {
        PageImageView(viewModel: viewModel, pageIndex: rightPageIndex)
          .frame(width: screenSize.width / 2, height: screenSize.height)
      } else {
        // Empty space for odd number of pages
        readerBackground.color
          .frame(width: screenSize.width / 2, height: screenSize.height)
      }

      // Left page (for RTL, left page is on the right side of screen)
      PageImageView(viewModel: viewModel, pageIndex: leftPageIndex)
        .frame(width: screenSize.width / 2, height: screenSize.height)
    }
  }
}
