//
//  DualPageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct DualPageView: View {
  @Bindable var viewModel: ReaderViewModel
  let pagePair: PagePair
  let screenSize: CGSize
  let isRTL: Bool

  @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .system

  var body: some View {
    HStack(spacing: 0) {
      if let second = pagePair.second {
        if isRTL {
          PageImageView(viewModel: viewModel, pageIndex: second)
            .frame(width: screenSize.width / 2, height: screenSize.height)
          PageImageView(viewModel: viewModel, pageIndex: pagePair.first)
            .frame(width: screenSize.width / 2, height: screenSize.height)
        } else {
          PageImageView(viewModel: viewModel, pageIndex: pagePair.first)
            .frame(width: screenSize.width / 2, height: screenSize.height)
          PageImageView(viewModel: viewModel, pageIndex: second)
            .frame(width: screenSize.width / 2, height: screenSize.height)
        }
      } else {
        PageImageView(viewModel: viewModel, pageIndex: pagePair.first)
          .frame(width: screenSize.width / 2, height: screenSize.height)
      }
    }
  }
}
