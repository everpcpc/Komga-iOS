//
//  WebtoonPageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct WebtoonPageView: View {
  let viewModel: ReaderViewModel
  @Binding var currentPage: Int
  @Binding var isAtBottom: Bool
  let nextBook: Book?
  let onDismiss: () -> Void
  let onNextBook: (String) -> Void
  let toggleControls: () -> Void

  @AppStorage("webtoonPageWidthPercentage") private var webtoonPageWidthPercentage: Double = 100.0

  var body: some View {
    GeometryReader { geometry in
      let screenWidth = geometry.size.width
      let pageWidth = screenWidth * (webtoonPageWidthPercentage / 100.0)

      ZStack {
        WebtoonReaderView(
          pages: viewModel.pages,
          currentPage: $currentPage,
          viewModel: viewModel,
          pageWidth: pageWidth,
          onPageChange: { pageIndex in
            viewModel.currentPage = pageIndex
          },
          onCenterTap: {
            toggleControls()
          },
          onScrollToBottom: { atBottom in
            isAtBottom = atBottom
          }
        )

        if isAtBottom {
          VStack {
            Spacer()
            EndPageView(
              nextBook: nextBook,
              onDismiss: onDismiss,
              onNextBook: onNextBook
            )
            .padding(.bottom, 120)
          }
          .transition(.opacity)
        }
      }
      .ignoresSafeArea()
    }
  }
}
