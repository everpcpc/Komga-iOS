//
//  MangaPageView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct MangaPageView: View {
  @Bindable var viewModel: ReaderViewModel
  @Binding var isAtEndPage: Bool
  @Binding var showingControls: Bool
  let nextBook: Book?
  let onDismiss: () -> Void
  let onNextBook: (String) -> Void
  let goToNextPage: () -> Void
  let goToPreviousPage: () -> Void
  let toggleControls: () -> Void

  @State private var hasSyncedInitialScroll = false
  @State private var showTapZoneOverlay = false
  @State private var scrollPosition: MangaScrollTarget?
  @AppStorage("showTapZone") private var showTapZone: Bool = true
  @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .system

  var body: some View {
    GeometryReader { screenGeometry in
      let screenKey =
        "\(Int(screenGeometry.size.width))x\(Int(screenGeometry.size.height))"

      ZStack {
        ScrollViewReader { proxy in
          ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
              // End page at the beginning for RTL
              ZStack {
                readerBackground.color.ignoresSafeArea()
                EndPageView(
                  nextBook: nextBook,
                  onDismiss: onDismiss,
                  onNextBook: onNextBook,
                  isRTL: true,
                )
              }
              .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
              .contentShape(Rectangle())
              .simultaneousGesture(
                horizontalTapGesture(width: screenGeometry.size.width, proxy: proxy)
              )
              .id(MangaScrollTarget.endPage)

              // Pages in reverse order for RTL (last to first)
              ForEach((0..<viewModel.pages.count).reversed(), id: \.self) { pageIndex in
                PageImageView(viewModel: viewModel, pageIndex: pageIndex)
                  .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
                  .contentShape(Rectangle())
                  .simultaneousGesture(
                    horizontalTapGesture(width: screenGeometry.size.width, proxy: proxy)
                  )
                  .id(MangaScrollTarget.page(pageIndex))
              }
            }
            .scrollTargetLayout()
          }
          .scrollTargetBehavior(.paging)
          .scrollIndicators(.hidden)
          .scrollPosition(id: $scrollPosition)
          .onAppear {
            synchronizeInitialScrollIfNeeded(proxy: proxy)
          }
          .onChange(of: viewModel.pages.count) { _, _ in
            hasSyncedInitialScroll = false
            synchronizeInitialScrollIfNeeded(proxy: proxy)
          }
          .id(screenKey)
          .onChange(of: screenKey) { _, _ in
            // Reset scroll sync flag when screen size changes
            hasSyncedInitialScroll = false
          }
          .onChange(of: scrollPosition) { _, newTarget in
            handleScrollPositionChange(newTarget)
          }
        }

        // Tap zone overlay
        if showTapZoneOverlay {
          PageTapZoneOverlay(
            orientation: .horizontal,
            isRTL: true
          )
        }
      }
      .onAppear {
        // Show tap zone overlay when view appears with pages loaded
        if showTapZone && !viewModel.pages.isEmpty && !showTapZoneOverlay {
          showTapZoneOverlay = true
        }
      }
      .onChange(of: viewModel.pages.count) { oldCount, newCount in
        // Show tap zone overlay when pages are first loaded
        if oldCount == 0 && newCount > 0 {
          triggerTapZoneDisplay()
        }
      }
      .onChange(of: screenKey) {
        // Show tap zone overlay when screen orientation changes
        triggerTapZoneDisplay()
      }
    }
  }

  private func triggerTapZoneDisplay() {
    guard showTapZone && !viewModel.pages.isEmpty else { return }
    showTapZoneOverlay = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      showTapZoneOverlay = true
    }
  }

  private func horizontalTapGesture(width: CGFloat, proxy: ScrollViewProxy) -> some Gesture {
    SpatialTapGesture()
      .onEnded { value in
        guard width > 0 else { return }
        let normalizedX = max(0, min(1, value.location.x / width))
        if normalizedX < 0.35 {
          // Next page (left tap for RTL means go forward)
          if viewModel.currentPageIndex < viewModel.pages.count - 1 {
            viewModel.currentPageIndex += 1
            isAtEndPage = false
            withAnimation {
              scrollPosition = .page(viewModel.currentPageIndex)
              proxy.scrollTo(MangaScrollTarget.page(viewModel.currentPageIndex), anchor: .leading)
            }
          } else {
            isAtEndPage = true
            withAnimation {
              scrollPosition = .endPage
              proxy.scrollTo(MangaScrollTarget.endPage, anchor: .leading)
            }
          }
        } else if normalizedX > 0.65 {
          // Previous page (right tap for RTL means go back)
          if isAtEndPage {
            viewModel.currentPageIndex = viewModel.pages.count - 1
            isAtEndPage = false
            withAnimation {
              scrollPosition = .page(viewModel.currentPageIndex)
              proxy.scrollTo(MangaScrollTarget.page(viewModel.currentPageIndex), anchor: .leading)
            }
          } else if viewModel.currentPageIndex > 0 {
            viewModel.currentPageIndex -= 1
            withAnimation {
              scrollPosition = .page(viewModel.currentPageIndex)
              proxy.scrollTo(MangaScrollTarget.page(viewModel.currentPageIndex), anchor: .leading)
            }
          }
        } else {
          toggleControls()
        }
      }
  }

  private func synchronizeInitialScrollIfNeeded(proxy: ScrollViewProxy) {
    guard !hasSyncedInitialScroll,
      viewModel.currentPageIndex >= 0,
      viewModel.currentPageIndex < viewModel.pages.count
    else {
      return
    }

    DispatchQueue.main.async {
      scrollPosition = .page(viewModel.currentPageIndex)
      proxy.scrollTo(MangaScrollTarget.page(viewModel.currentPageIndex), anchor: .leading)
      hasSyncedInitialScroll = true
    }
  }

  private func handleScrollPositionChange(_ target: MangaScrollTarget?) {
    guard hasSyncedInitialScroll, let target else { return }

    switch target {
    case .page(let index):
      if isAtEndPage {
        isAtEndPage = false
      }
      if viewModel.currentPageIndex != index {
        viewModel.currentPageIndex = index
        Task(priority: .userInitiated) {
          await viewModel.preloadPages()
        }
      }
    case .endPage:
      if !isAtEndPage {
        isAtEndPage = true
      }
      showingControls = true
    }
  }
}

private enum MangaScrollTarget: Hashable {
  case page(Int)
  case endPage
}
