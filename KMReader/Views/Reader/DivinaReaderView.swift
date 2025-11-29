//
//  DivinaReaderView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import SwiftUI

struct DivinaReaderView: View {
  let incognito: Bool

  @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .system
  @AppStorage("pageLayout") private var pageLayout: PageLayout = .dual

  @Environment(\.dismiss) private var dismiss

  @State private var currentBookId: String
  @State private var viewModel = ReaderViewModel()
  @State private var showingControls = true
  @State private var controlsTimer: Timer?
  @State private var currentBook: Book?
  @State private var seriesId: String?
  @State private var nextBook: Book?
  @State private var isAtBottom = false
  @State private var showingReadingDirectionPicker = false
  @State private var readingDirection: ReadingDirection = .ltr
  @State private var showTapZoneOverlay = false
  @State private var overlayTimer: Timer?

  init(bookId: String, incognito: Bool = false) {
    self.incognito = incognito
    self._currentBookId = State(initialValue: bookId)
  }

  var shouldShowControls: Bool {
    // Always show controls when no pages are loaded or when explicitly shown
    viewModel.pages.isEmpty || showingControls || isShowingEndPage
      || (readingDirection == .webtoon && isAtBottom)
  }

  private var isShowingEndPage: Bool {
    guard !viewModel.pages.isEmpty else { return false }
    return viewModel.currentPageIndex >= viewModel.pages.count
  }

  private func shouldUseDualPage(screenSize: CGSize) -> Bool {
    guard screenSize.width > screenSize.height else { return false }  // Only in landscape
    return pageLayout == .dual
  }

  var body: some View {
    GeometryReader { geometry in
      let screenKey = "\(Int(geometry.size.width))x\(Int(geometry.size.height))"
      let useDualPage = shouldUseDualPage(screenSize: geometry.size)

      ZStack {
        readerBackground.color.ignoresSafeArea()

        if !viewModel.pages.isEmpty {
          // Page viewer based on reading direction
          Group {
            switch readingDirection {
            case .ltr:
              if useDualPage {
                ComicDualPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              } else {
                ComicPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              }

            case .rtl:
              if useDualPage {
                MangaDualPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              } else {
                MangaPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              }

            case .vertical:
              if useDualPage {
                VerticalDualPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              } else {
                VerticalPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              }

            case .webtoon:
              #if canImport(UIKit)
                WebtoonPageView(
                  viewModel: viewModel,
                  isAtBottom: $isAtBottom,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              #else
                // Webtoon requires UIKit, fallback to vertical
                VerticalPageView(
                  viewModel: viewModel,
                  nextBook: nextBook,
                  onDismiss: { dismiss() },
                  onNextBook: { openNextBook(nextBookId: $0) },
                  goToNextPage: goToNextPage,
                  goToPreviousPage: goToPreviousPage,
                  toggleControls: toggleControls,
                  screenSize: geometry.size
                ).ignoresSafeArea()
              #endif
            }
          }
          .id(screenKey)
          #if canImport(AppKit)
            .background(
              // Window-level keyboard event handler
              KeyboardEventHandler(
                onKeyPress: { [dismiss] keyCode, flags in
                  handleKeyCode(keyCode, flags: flags, dismiss: dismiss)
                }
              )
            )
          #endif
          .onChange(of: viewModel.currentPageIndex) {
            // Update progress and preload pages in background without blocking UI
            Task(priority: .userInitiated) {
              await viewModel.updateProgress()
              await viewModel.preloadPages()
            }
          }
        } else if viewModel.isLoading {
          // Show loading indicator when loading
          ProgressView()
            .tint(.white)
        } else {
          // No pages available
          NoPagesView(
            onDismiss: { dismiss() }
          )
        }

        // Tap zone overlay(always rendered, use opacity to control visibility)
        Group {
          switch readingDirection {
          case .ltr:
            ComicTapZoneOverlay(isVisible: $showTapZoneOverlay)
          case .rtl:
            MangaTapZoneOverlay(isVisible: $showTapZoneOverlay)
          case .vertical:
            VerticalTapZoneOverlay(isVisible: $showTapZoneOverlay)
          case .webtoon:
            #if canImport(UIKit)
              WebtoonTapZoneOverlay(isVisible: $showTapZoneOverlay)
            #else
              // Webtoon requires UIKit, fallback to vertical
              VerticalTapZoneOverlay(isVisible: $showTapZoneOverlay)
            #endif
          }
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.pages.count) { oldCount, newCount in
          // Show tap zone overlay when pages are first loaded
          if oldCount == 0 && newCount > 0 {
            triggerTapZoneDisplay()
          }
        }
        .onChange(of: showTapZoneOverlay) { _, newValue in
          if newValue {
            resetOverlayTimer()
          } else {
            overlayTimer?.invalidate()
          }
        }
        .onChange(of: screenKey) {
          // Show tap zone overlay when screen orientation changes
          if !viewModel.pages.isEmpty {
            triggerTapZoneDisplay()
          }
        }

        // Controls overlay (always rendered, use opacity to control visibility)
        ReaderControlsView(
          showingControls: $showingControls,
          showingReadingDirectionPicker: $showingReadingDirectionPicker,
          readingDirection: $readingDirection,
          viewModel: viewModel,
          currentBook: currentBook,
          dualPage: useDualPage,
          onDismiss: { dismiss() }
        )
        .padding(.vertical, 24)
        .padding(.horizontal, 8)
        .ignoresSafeArea()
        .opacity(shouldShowControls ? 1.0 : 0.0)
        .allowsHitTesting(shouldShowControls)
      }
    }
    .ignoresSafeArea()
    #if canImport(UIKit)
      .statusBar(hidden: !shouldShowControls)
    #endif
    .task(id: currentBookId) {
      await loadBook(bookId: currentBookId)
    }
    .onDisappear {
      controlsTimer?.invalidate()
      overlayTimer?.invalidate()
    }
  }

  private func loadBook(bookId: String) async {
    // Mark that loading has started
    viewModel.isLoading = true

    // Set incognito mode
    viewModel.incognitoMode = incognito

    // Reset isAtBottom when switching to a new book
    isAtBottom = false

    // Load book info to get read progress page and series reading direction
    var initialPageNumber: Int? = nil
    do {
      let book = try await BookService.shared.getBook(id: bookId)
      currentBook = book
      seriesId = book.seriesId
      // In incognito mode, always start from the first page
      initialPageNumber = incognito ? nil : book.readProgress?.page

      // Get series reading direction
      let series = try await SeriesService.shared.getOneSeries(id: book.seriesId)
      if let readingDirectionString = series.metadata.readingDirection {
        let direction = ReadingDirection.fromString(readingDirectionString)
        // Fallback to vertical if webtoon is not supported on current platform
        readingDirection = direction.isSupported ? direction : .vertical
      }

      // Load next book
      if let nextBook = try await BookService.shared.getNextBook(bookId: bookId) {
        self.nextBook = nextBook
      } else {
        nextBook = nil
      }
    } catch {
      // Silently fail, will start from first page
    }

    let resumePageNumber = viewModel.currentPage?.number ?? initialPageNumber

    await viewModel.loadPages(
      bookId: bookId,
      initialPageNumber: resumePageNumber,
    )

    // Only preload pages if pages are available
    if viewModel.pages.isEmpty {
      return
    }
    await viewModel.preloadPages()
    // Start timer to auto-hide controls after 3 seconds when entering reader
    resetControlsTimer()
  }

  private func goToNextPage() {
    guard !viewModel.pages.isEmpty else { return }
    switch readingDirection {
    case .ltr, .rtl, .vertical:
      // Check if we're in dual page mode by checking if currentPageIndex has a PagePair
      let currentPair = viewModel.dualPageIndices[viewModel.currentPageIndex]
      if let currentPair = currentPair, shouldUseDualPage(screenSize: getCurrentScreenSize()) {
        // Dual page mode: calculate next page based on current pair
        if let second = currentPair.second {
          viewModel.targetPageIndex = min(viewModel.pages.count, second + 1)
        } else {
          viewModel.targetPageIndex = min(viewModel.pages.count, currentPair.first + 1)
        }
      } else {
        // Single page mode: simple increment
        let next = min(viewModel.currentPageIndex + 1, viewModel.pages.count)
        viewModel.targetPageIndex = next
      }
    case .webtoon:
      // webtoon do not have an end page
      let next = min(viewModel.currentPageIndex + 1, viewModel.pages.count - 1)
      withAnimation {
        viewModel.currentPageIndex = next
      }
    }
  }

  private func goToPreviousPage() {
    guard !viewModel.pages.isEmpty else { return }
    switch readingDirection {
    case .ltr, .rtl, .vertical:
      guard viewModel.currentPageIndex > 0 else { return }
      // Check if we're in dual page mode by checking if currentPageIndex has a PagePair
      let currentPair = viewModel.dualPageIndices[viewModel.currentPageIndex]
      if let currentPair = currentPair, shouldUseDualPage(screenSize: getCurrentScreenSize()) {
        // Dual page mode: go to previous pair's first page
        viewModel.targetPageIndex = max(0, currentPair.first - 1)
      } else {
        // Single page mode: simple decrement
        let previous = viewModel.currentPageIndex - 1
        viewModel.targetPageIndex = previous
      }
    case .webtoon:
      guard viewModel.currentPageIndex > 0 else { return }
      withAnimation {
        viewModel.currentPageIndex -= 1
      }
    }
  }

  #if canImport(UIKit)
    private func getCurrentScreenSize() -> CGSize {
      return UIScreen.main.bounds.size
    }
  #elseif canImport(AppKit)
    private func getCurrentScreenSize() -> CGSize {
      return NSScreen.main?.frame.size ?? CGSize(width: 1024, height: 768)
    }
  #else
    private func getCurrentScreenSize() -> CGSize {
      return CGSize(width: 1024, height: 768)
    }
  #endif

  private func toggleControls() {
    // Don't hide controls when at end page or webtoon at bottom
    if isShowingEndPage || (readingDirection == .webtoon && isAtBottom) {
      return
    }
    withAnimation {
      showingControls.toggle()
    }
    if showingControls {
      resetControlsTimer()
    }
  }

  private func resetControlsTimer() {
    // Don't start timer when at end page or webtoon at bottom
    if isShowingEndPage || (readingDirection == .webtoon && isAtBottom) {
      return
    }
    controlsTimer?.invalidate()
    controlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
      withAnimation {
        showingControls = false
      }
    }
  }

  private func triggerTapZoneDisplay() {
    guard !viewModel.pages.isEmpty else { return }
    showTapZoneOverlay = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      showTapZoneOverlay = true
    }
  }

  private func resetOverlayTimer() {
    overlayTimer?.invalidate()
    overlayTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
      withAnimation {
        showTapZoneOverlay = false
      }
    }
  }

  private func openNextBook(nextBookId: String) {
    // Switch to next book by updating currentBookId
    // This will trigger the .task(id: currentBookId) to reload
    currentBookId = nextBookId
    // Reset viewModel state for new book
    viewModel = ReaderViewModel()
    // Preserve incognito mode for next book
    viewModel.incognitoMode = incognito
    // Reset isAtBottom so buttons hide until user scrolls to bottom
    isAtBottom = false
    // Reset overlay state
    showTapZoneOverlay = false
  }

  #if canImport(AppKit)
    private func handleKeyCode(
      _ keyCode: UInt16, flags: NSEvent.ModifierFlags, dismiss: DismissAction
    ) {
      // Handle ESC key to close window
      if keyCode == 53 {  // ESC key
        dismiss()
        return
      }

      guard !viewModel.pages.isEmpty else { return }

      // Ignore if modifier keys are pressed (except for system shortcuts)
      guard flags.intersection([.command, .option, .control]).isEmpty else { return }

      switch readingDirection {
      case .ltr:
        switch keyCode {
        case 124:  // Right arrow
          goToNextPage()
        case 123:  // Left arrow
          goToPreviousPage()
        default:
          break
        }
      case .rtl:
        switch keyCode {
        case 123:  // Left arrow
          goToNextPage()
        case 124:  // Right arrow
          goToPreviousPage()
        default:
          break
        }
      case .vertical:
        switch keyCode {
        case 125, 124:  // Down arrow, Right arrow
          goToNextPage()
        case 126, 123:  // Up arrow, Left arrow
          goToPreviousPage()
        default:
          break
        }
      case .webtoon:
        switch keyCode {
        case 125, 124:  // Down arrow, Right arrow
          goToNextPage()
        case 126, 123:  // Up arrow, Left arrow
          goToPreviousPage()
        default:
          break
        }
      }
    }
  #endif
}

#if canImport(AppKit)
  import AppKit

  // Window-level keyboard event handler
  private struct KeyboardEventHandler: NSViewRepresentable {
    let onKeyPress: (UInt16, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> KeyboardHandlerView {
      let view = KeyboardHandlerView()
      view.onKeyPress = onKeyPress
      return view
    }

    func updateNSView(_ nsView: KeyboardHandlerView, context: Context) {
      nsView.onKeyPress = onKeyPress
    }
  }

  private class KeyboardHandlerView: NSView {
    var onKeyPress: ((UInt16, NSEvent.ModifierFlags) -> Void)?

    override var acceptsFirstResponder: Bool {
      return true
    }

    override func becomeFirstResponder() -> Bool {
      return true
    }

    override func keyDown(with event: NSEvent) {
      onKeyPress?(event.keyCode, event.modifierFlags)
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      // Make this view the first responder when added to window
      DispatchQueue.main.async { [weak self] in
        self?.window?.makeFirstResponder(self)
      }
    }
  }
#endif
