//
//  WebtoonReaderView.swift
//  Komga
//
//  Created by Komga iOS Client
//

import ImageIO
import SDWebImage
import SwiftUI

private enum Constants {
  static let initialScrollDelay: TimeInterval = 0.3
  static let layoutReadyDelay: TimeInterval = 0.2
  static let centerTapHandlingDelay: TimeInterval = 0.2
  static let preloadThrottleInterval: TimeInterval = 0.3
  static let scrollPositionThreshold: CGFloat = 50
  static let heightChangeThreshold: CGFloat = 100
  static let bottomThreshold: CGFloat = 80
  static let footerHeight: CGFloat = 360
  static let estimatedAspectRatio: CGFloat = 1.5
  static let scrollAmountMultiplier: CGFloat = 0.8
  static let topAreaThreshold: CGFloat = 0.3
  static let bottomAreaThreshold: CGFloat = 0.7
  static let centerAreaMin: CGFloat = 0.3
  static let centerAreaMax: CGFloat = 0.7
}

struct WebtoonReaderView: UIViewRepresentable {
  let pages: [BookPage]
  @Binding var currentPage: Int
  let viewModel: ReaderViewModel
  let onPageChange: ((Int) -> Void)?
  let onCenterTap: (() -> Void)?
  let onScrollToBottom: ((Bool) -> Void)?
  let pageWidth: CGFloat

  init(
    pages: [BookPage], currentPage: Binding<Int>, viewModel: ReaderViewModel,
    pageWidth: CGFloat,
    onPageChange: ((Int) -> Void)? = nil,
    onCenterTap: (() -> Void)? = nil,
    onScrollToBottom: ((Bool) -> Void)? = nil
  ) {
    self.pages = pages
    self._currentPage = currentPage
    self.viewModel = viewModel
    self.pageWidth = pageWidth
    self.onPageChange = onPageChange
    self.onCenterTap = onCenterTap
    self.onScrollToBottom = onScrollToBottom
  }

  func makeUIView(context: Context) -> UICollectionView {
    let layout = WebtoonLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.delegate = context.coordinator
    collectionView.dataSource = context.coordinator
    collectionView.backgroundColor = .black
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.bounces = false
    collectionView.scrollsToTop = false
    collectionView.isPrefetchingEnabled = true

    collectionView.register(WebtoonPageCell.self, forCellWithReuseIdentifier: "WebtoonPageCell")
    collectionView.register(WebtoonFooterCell.self, forCellWithReuseIdentifier: "WebtoonFooterCell")

    let tapGesture = UITapGestureRecognizer(
      target: context.coordinator,
      action: #selector(Coordinator.handleTap(_:))
    )
    tapGesture.numberOfTapsRequired = 1
    collectionView.addGestureRecognizer(tapGesture)

    context.coordinator.collectionView = collectionView
    context.coordinator.layout = layout
    context.coordinator.scheduleInitialScroll()

    return collectionView
  }

  func updateUIView(_ collectionView: UICollectionView, context: Context) {
    context.coordinator.update(
      pages: pages,
      currentPage: currentPage,
      viewModel: viewModel,
      onPageChange: onPageChange,
      onCenterTap: onCenterTap,
      onScrollToBottom: onScrollToBottom,
      pageWidth: pageWidth,
      collectionView: collectionView
    )
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
  {
    var parent: WebtoonReaderView
    var collectionView: UICollectionView?
    var layout: WebtoonLayout?
    var pages: [BookPage] = []
    var currentPage: Int = 0
    weak var viewModel: ReaderViewModel?
    var onPageChange: ((Int) -> Void)?
    var onCenterTap: (() -> Void)?
    var onScrollToBottom: ((Bool) -> Void)?
    var lastPagesCount: Int = 0
    var lastExternalCurrentPage: Int = -1
    var isUserScrolling: Bool = false
    var hasScrolledToInitialPage: Bool = false
    var lastPreloadTime: Date?
    var pageWidth: CGFloat = 0
    var lastPageWidth: CGFloat = 0
    var isAtBottom: Bool = false
    var isHandlingCenterTap: Bool = false
    var savedScrollOffset: CGFloat = 0
    var lastVisibleCellsUpdateTime: Date?
    var frameMonitorTimer: Timer?

    var pageHeights: [Int: CGFloat] = [:]
    var loadingPages: Set<Int> = []

    init(_ parent: WebtoonReaderView) {
      self.parent = parent
      self.pages = parent.pages
      self.currentPage = parent.currentPage
      self.lastExternalCurrentPage = parent.currentPage
      self.viewModel = parent.viewModel
      self.onPageChange = parent.onPageChange
      self.onCenterTap = parent.onCenterTap
      self.onScrollToBottom = parent.onScrollToBottom
      self.lastPagesCount = parent.pages.count
      self.hasScrolledToInitialPage = false
      self.pageWidth = parent.pageWidth
      self.lastPageWidth = parent.pageWidth
    }

    // MARK: - Helper Methods

    /// Validates if a page index is within valid range
    func isValidPageIndex(_ index: Int) -> Bool {
      index >= 0 && index < pages.count
    }

    /// Calculates estimated height for a page
    func estimatedPageHeight() -> CGFloat {
      pageWidth * Constants.estimatedAspectRatio
    }

    /// Schedules initial scroll after view appears
    func scheduleInitialScroll() {
      DispatchQueue.main.asyncAfter(deadline: .now() + Constants.initialScrollDelay) {
        [weak self] in
        guard let self = self,
          !self.hasScrolledToInitialPage,
          self.pages.count > 0,
          self.isValidPageIndex(self.currentPage)
        else { return }
        self.scrollToInitialPage(self.currentPage)
      }
    }

    /// Executes code after a delay
    func executeAfterDelay(_ delay: TimeInterval, _ block: @escaping () -> Void) {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }

    /// Calculates offset to a page index
    func calculateOffsetToPage(_ pageIndex: Int) -> CGFloat {
      var offset: CGFloat = 0
      for i in 0..<pageIndex {
        if let height = pageHeights[i] {
          offset += height
        } else {
          offset += estimatedPageHeight()
        }
      }
      return offset
    }

    /// Updates coordinator state and handles view updates
    func update(
      pages: [BookPage],
      currentPage: Int,
      viewModel: ReaderViewModel,
      onPageChange: ((Int) -> Void)?,
      onCenterTap: (() -> Void)?,
      onScrollToBottom: ((Bool) -> Void)?,
      pageWidth: CGFloat,
      collectionView: UICollectionView
    ) {
      self.pages = pages
      self.currentPage = currentPage
      self.viewModel = viewModel
      self.onPageChange = onPageChange
      self.onCenterTap = onCenterTap
      self.onScrollToBottom = onScrollToBottom
      self.pageWidth = pageWidth

      if lastPagesCount != pages.count || abs(lastPageWidth - pageWidth) > 0.1 {
        handleDataReload(collectionView: collectionView, currentPage: currentPage)
        if abs(lastPageWidth - pageWidth) > 0.1 {
          updateVisibleCellsPageWidth(collectionView: collectionView)
        }
      }

      if isHandlingCenterTap {
        handleCenterTapState(currentPage: currentPage)
        return
      }

      if !hasScrolledToInitialPage && pages.count > 0 && isValidPageIndex(currentPage) {
        scrollToInitialPage(currentPage)
      }

      // Start frame monitor to continuously correct frame of visible cells
      startFrameMonitor()
    }

    private func updateVisibleCellsPageWidth(collectionView: UICollectionView) {
      let visibleIndexPaths = collectionView.indexPathsForVisibleItems
      for indexPath in visibleIndexPaths {
        if indexPath.item < pages.count,
          let cell = collectionView.cellForItem(at: indexPath) as? WebtoonPageCell
        {
          // Always set pageWidth first
          cell.setPageWidth(pageWidth)
          // Force update frame immediately - call multiple times to ensure it sticks
          cell.forceUpdateFrame()
          cell.forceUpdateFrame()
        }
      }
    }

    /// Handles data reload when pages count or width changes
    private func handleDataReload(collectionView: UICollectionView, currentPage: Int) {
      lastPagesCount = pages.count
      lastPageWidth = pageWidth
      hasScrolledToInitialPage = false
      collectionView.reloadData()
      collectionView.layoutIfNeeded()

      if isValidPageIndex(currentPage) {
        executeAfterDelay(Constants.layoutReadyDelay) { [weak self] in
          self?.scrollToInitialPage(currentPage)
        }
        executeAfterDelay(0.5) { [weak self] in
          guard let self = self, !self.hasScrolledToInitialPage else { return }
          self.scrollToInitialPage(currentPage)
        }
      }
    }

    /// Handles center tap state to preserve scroll position
    private func handleCenterTapState(currentPage: Int) {
      if savedScrollOffset > 0, let collectionView = collectionView {
        let currentOffset = collectionView.contentOffset.y
        if abs(currentOffset - savedScrollOffset) > Constants.scrollPositionThreshold {
          collectionView.setContentOffset(
            CGPoint(x: 0, y: savedScrollOffset),
            animated: false
          )
        }
      }
      lastExternalCurrentPage = currentPage
    }

    func scrollToPage(_ pageIndex: Int, animated: Bool) {
      guard let collectionView = collectionView, isValidPageIndex(pageIndex) else { return }

      let indexPath = IndexPath(item: pageIndex, section: 0)

      if collectionView.contentSize.height > 0 {
        collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
      } else {
        DispatchQueue.main.async { [weak self] in
          guard let self = self, let collectionView = self.collectionView else { return }
          if collectionView.contentSize.height > 0 {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
          } else {
            let offset = self.calculateOffsetToPage(pageIndex)
            collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
          }
        }
      }
    }

    func scrollToInitialPage(_ pageIndex: Int) {
      guard !hasScrolledToInitialPage else { return }
      guard let collectionView = collectionView,
        isValidPageIndex(pageIndex),
        collectionView.bounds.width > 0 && collectionView.bounds.height > 0
      else {
        if !hasScrolledToInitialPage {
          executeAfterDelay(0.1) { [weak self] in
            self?.scrollToInitialPage(pageIndex)
          }
        }
        return
      }

      collectionView.layoutIfNeeded()

      guard collectionView.contentSize.height > 0 else {
        if !hasScrolledToInitialPage {
          executeAfterDelay(Constants.layoutReadyDelay) { [weak self] in
            self?.scrollToInitialPage(pageIndex)
          }
        }
        return
      }

      let indexPath = IndexPath(item: pageIndex, section: 0)
      collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
      collectionView.layoutIfNeeded()

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.hasScrolledToInitialPage = true
        self.lastExternalCurrentPage = pageIndex
      }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
      -> Int
    {
      pages.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
      -> UICollectionViewCell
    {
      if indexPath.item == pages.count {
        let cell =
          collectionView.dequeueReusableCell(
            withReuseIdentifier: "WebtoonFooterCell", for: indexPath)
          as! WebtoonFooterCell
        return cell
      }

      let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier: "WebtoonPageCell", for: indexPath)
        as! WebtoonPageCell

      let pageIndex = indexPath.item

      // Set pageWidth and force update frame immediately, even if cell is not yet visible
      // This ensures correct width from the start
      cell.setPageWidth(pageWidth)
      cell.forceUpdateFrame()

      // Also update asynchronously to catch any delayed bounds updates
      DispatchQueue.main.async {
        cell.forceUpdateFrame()
      }

      Task { @MainActor [weak self] in
        guard let self = self else { return }
        await self.loadImageForPage(pageIndex)
      }

      cell.configure(
        pageIndex: pageIndex,
        image: nil,
        loadImage: { [weak self] index in
          guard let self = self else { return }
          Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.loadImageForPage(index)
          }
        }
      )

      // Force update frame again after configure
      cell.forceUpdateFrame()

      return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
      _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      if indexPath.item == pages.count {
        return CGSize(width: pageWidth, height: Constants.footerHeight)
      }

      if let height = pageHeights[indexPath.item] {
        return CGSize(width: pageWidth, height: height)
      }

      return CGSize(width: pageWidth, height: pageWidth)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(
      _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
      forItemAt indexPath: IndexPath
    ) {
      if let webtoonCell = cell as? WebtoonPageCell {
        webtoonCell.setPageWidth(pageWidth)
        // Force update frame immediately when cell is about to display
        webtoonCell.forceUpdateFrame()
        // Also update asynchronously to catch any delayed bounds updates
        DispatchQueue.main.async {
          webtoonCell.forceUpdateFrame()
        }
      }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      isUserScrolling = true
      // Ensure frame monitor is running during scrolling
      startFrameMonitor()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      checkIfAtBottom(scrollView)

      if isUserScrolling {
        updateCurrentPage()
        throttlePreload()
        // Update visible cells on every scroll event, no throttling
        if let collectionView = collectionView {
          updateVisibleCellsPageWidth(collectionView: collectionView)
        }
      }
    }

    /// Throttles preload calls to avoid too frequent updates
    private func throttlePreload() {
      let now = Date()
      if lastPreloadTime == nil
        || now.timeIntervalSince(lastPreloadTime!) > Constants.preloadThrottleInterval
      {
        lastPreloadTime = now
        preloadNearbyPages()
      }
    }

    /// Starts a timer to continuously monitor and correct frame of visible cells
    private func startFrameMonitor() {
      stopFrameMonitor()
      frameMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
        [weak self] _ in
        guard let self = self, let collectionView = self.collectionView else { return }
        self.updateVisibleCellsPageWidth(collectionView: collectionView)
      }
      // Add timer to common run loop modes so it runs during scrolling
      RunLoop.current.add(frameMonitorTimer!, forMode: .common)
    }

    /// Stops the frame monitor timer
    private func stopFrameMonitor() {
      frameMonitorTimer?.invalidate()
      frameMonitorTimer = nil
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      isUserScrolling = false
      checkIfAtBottom(scrollView)
      updateCurrentPage()
      preloadNearbyPages()
      if let collectionView = collectionView {
        updateVisibleCellsPageWidth(collectionView: collectionView)
      }
      // Keep frame monitor running to catch any delayed frame changes
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      if !decelerate {
        isUserScrolling = false
        checkIfAtBottom(scrollView)
        updateCurrentPage()
        preloadNearbyPages()
        if let collectionView = collectionView {
          updateVisibleCellsPageWidth(collectionView: collectionView)
        }
        // Keep frame monitor running to catch any delayed frame changes
      }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
      isUserScrolling = false
      checkIfAtBottom(scrollView)
      updateCurrentPage()
      preloadNearbyPages()
    }

    private func checkIfAtBottom(_ scrollView: UIScrollView) {
      guard hasScrolledToInitialPage else {
        return
      }

      let contentHeight = scrollView.contentSize.height
      let scrollOffset = scrollView.contentOffset.y
      let scrollViewHeight = scrollView.bounds.height

      guard contentHeight > scrollViewHeight else {
        return
      }

      let isAtBottomNow =
        scrollOffset + scrollViewHeight >= contentHeight - Constants.bottomThreshold

      if isAtBottomNow != isAtBottom {
        isAtBottom = isAtBottomNow
        onScrollToBottom?(isAtBottom)

        if isAtBottomNow && pages.count > 0 {
          let lastPageIndex = pages.count - 1
          if let collectionView = collectionView {
            let visibleIndexPaths = collectionView.indexPathsForVisibleItems
              .filter { $0.item < pages.count }
            if visibleIndexPaths.contains(where: { $0.item == lastPageIndex }) {
              if currentPage != lastPageIndex {
                currentPage = lastPageIndex
                onPageChange?(lastPageIndex)
              }
            }
          }
        }
      }
    }

    private func updateCurrentPage() {
      guard let collectionView = collectionView else { return }

      let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        .filter { $0.item < pages.count }
        .sorted { $0.item < $1.item }

      if pages.count > 0 {
        let lastPageIndex = pages.count - 1
        if visibleIndexPaths.contains(where: { $0.item == lastPageIndex }) {
          let contentHeight = collectionView.contentSize.height
          let scrollOffset = collectionView.contentOffset.y
          let scrollViewHeight = collectionView.bounds.height

          if scrollOffset + scrollViewHeight >= contentHeight - Constants.bottomThreshold {
            if currentPage != lastPageIndex {
              currentPage = lastPageIndex
              onPageChange?(lastPageIndex)
              return
            }
          }
        }
      }

      let centerY = collectionView.contentOffset.y + collectionView.bounds.height / 2
      let centerPoint = CGPoint(x: collectionView.bounds.width / 2, y: centerY)

      if let indexPath = collectionView.indexPathForItem(at: centerPoint),
        indexPath.item != pages.count,
        indexPath.item != currentPage,
        isValidPageIndex(indexPath.item)
      {
        currentPage = indexPath.item
        onPageChange?(indexPath.item)
      } else {
        if let firstVisible = visibleIndexPaths.first {
          let midIndex = firstVisible.item + visibleIndexPaths.count / 2
          if isValidPageIndex(midIndex) && midIndex != currentPage {
            currentPage = midIndex
            onPageChange?(midIndex)
          }
        }
      }
    }

    // MARK: - Image Loading

    @MainActor
    func loadImageForPage(_ pageIndex: Int) async {
      guard isValidPageIndex(pageIndex),
        let viewModel = viewModel
      else {
        return
      }

      guard let imageURL = await viewModel.getPageImageFileURL(pageIndex: pageIndex) else {
        showImageError(for: pageIndex)
        return
      }

      let isFromCache = viewModel.pageImageCache.hasImage(
        forKey: pageIndex, bookId: viewModel.bookId)

      let imageSize = await getImageSize(from: imageURL)

      if let collectionView = collectionView {
        let indexPath = IndexPath(item: pageIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? WebtoonPageCell {
          cell.setImageURL(imageURL, imageSize: imageSize, pageWidth: pageWidth)
        }
      }

      if let size = imageSize {
        let aspectRatio = size.height / size.width
        let height = pageWidth * aspectRatio
        let oldHeight = pageHeights[pageIndex] ?? pageWidth
        pageHeights[pageIndex] = height

        updateLayoutIfNeeded(pageIndex: pageIndex, height: height, oldHeight: oldHeight)

        if let collectionView = collectionView {
          let indexPath = IndexPath(item: pageIndex, section: 0)
          if let cell = collectionView.cellForItem(at: indexPath) as? WebtoonPageCell {
            cell.setPageWidth(pageWidth)
            // Force update frame after height is determined
            cell.forceUpdateFrame()
            DispatchQueue.main.async {
              cell.forceUpdateFrame()
            }
          }
        }

        if !isFromCache {
          tryScrollToInitialPageIfNeeded(pageIndex: pageIndex)
        }
      }
    }

    /// Get image size from URL without fully loading the image
    private func getImageSize(from url: URL) async -> CGSize? {
      return await Task.detached {
        let cacheKey = SDWebImageManager.shared.cacheKey(for: url)
        if let cachedImage = SDImageCache.shared.imageFromCache(forKey: cacheKey) {
          return cachedImage.size
        }

        if url.isFileURL {
          guard let data = try? Data(contentsOf: url),
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil)
          else {
            return nil
          }

          guard
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
              as? [String: Any],
            let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat,
            let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat
          else {
            return nil
          }

          return CGSize(width: width, height: height)
        }

        return nil
      }.value
    }

    /// Updates layout if height changed significantly
    private func updateLayoutIfNeeded(pageIndex: Int, height: CGFloat, oldHeight: CGFloat) {
      let heightDiff = abs(height - oldHeight)

      if let collectionView = collectionView, let layout = layout {
        let indexPath = IndexPath(item: pageIndex, section: 0)
        let isVisible = collectionView.indexPathsForVisibleItems.contains(indexPath)

        if isVisible {
          layout.invalidateLayout()
          collectionView.layoutIfNeeded()

          if let cell = collectionView.cellForItem(at: indexPath) as? WebtoonPageCell {
            // Force update immediately
            cell.forceUpdateFrame()
            DispatchQueue.main.async {
              cell.setNeedsLayout()
              cell.layoutIfNeeded()
              cell.forceUpdateFrame()
              // One more update after layout
              DispatchQueue.main.async {
                cell.forceUpdateFrame()
              }
            }
          }
        } else if heightDiff > Constants.heightChangeThreshold {
          if !isUserScrolling {
            let currentOffset = collectionView.contentOffset.y
            layout.invalidateLayout()
            collectionView.layoutIfNeeded()

            if pageIndex < currentPage {
              let newOffset = max(0, currentOffset + (height - oldHeight))
              UIView.performWithoutAnimation {
                collectionView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
              }
            }
          } else {
            executeAfterDelay(0.3) { [weak self] in
              guard let self = self, !self.isUserScrolling,
                let collectionView = self.collectionView,
                let layout = self.layout
              else { return }
              let currentHeight = self.pageHeights[pageIndex] ?? 0
              if abs(currentHeight - oldHeight) > Constants.heightChangeThreshold {
                layout.invalidateLayout()
                collectionView.layoutIfNeeded()
              }
            }
          }
        }
      }
    }

    /// Tries to scroll to initial page if needed
    private func tryScrollToInitialPageIfNeeded(pageIndex: Int) {
      guard !hasScrolledToInitialPage,
        isValidPageIndex(currentPage),
        abs(pageIndex - currentPage) <= 3
      else { return }
      let targetPage = currentPage
      executeAfterDelay(0.1) { [weak self] in
        self?.scrollToInitialPage(targetPage)
      }
    }

    /// Shows error state for failed image load
    private func showImageError(for pageIndex: Int) {
      guard let collectionView = collectionView else { return }
      let indexPath = IndexPath(item: pageIndex, section: 0)
      if let cell = collectionView.cellForItem(at: indexPath) as? WebtoonPageCell {
        cell.showError()
      }
    }

    // Preload nearby pages
    func preloadNearbyPages() {
      guard let collectionView = collectionView else { return }

      let visibleIndexPaths = collectionView.indexPathsForVisibleItems
      guard !visibleIndexPaths.isEmpty else { return }

      let visibleIndices = Set(visibleIndexPaths.map { $0.item })

      let minVisible = visibleIndices.min() ?? 0
      let maxVisible = visibleIndices.max() ?? pages.count - 1

      Task { @MainActor [weak self] in
        guard let self = self,
          let viewModel = self.viewModel
        else { return }

        for i in max(0, minVisible - 2)...min(self.pages.count - 1, maxVisible + 2) {
          if !viewModel.pageImageCache.hasImage(forKey: i, bookId: viewModel.bookId) {
            await self.loadImageForPage(i)
          }
        }
      }
    }

    // MARK: - Tap Gesture Handling

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let collectionView = collectionView,
        let view = collectionView.superview
      else { return }

      let location = gesture.location(in: view)
      let screenHeight = view.bounds.height
      let screenWidth = view.bounds.width

      let tapArea = determineTapArea(
        location: location, screenWidth: screenWidth, screenHeight: screenHeight)

      switch tapArea {
      case .center:
        handleCenterTap(collectionView: collectionView)
      case .topLeft:
        scrollUp(collectionView: collectionView, screenHeight: screenHeight)
      case .bottomRight:
        scrollDown(collectionView: collectionView, screenHeight: screenHeight)
      }
    }

    /// Determines which area was tapped
    private enum TapArea {
      case center
      case topLeft
      case bottomRight
    }

    private func determineTapArea(location: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat)
      -> TapArea
    {
      let isTopArea = location.y < screenHeight * Constants.topAreaThreshold
      let isBottomArea = location.y > screenHeight * Constants.bottomAreaThreshold
      let isMiddleArea = !isTopArea && !isBottomArea
      let isLeftArea = location.x < screenWidth * Constants.topAreaThreshold

      let isCenterArea =
        location.x > screenWidth * Constants.centerAreaMin
        && location.x < screenWidth * Constants.centerAreaMax
        && location.y > screenHeight * Constants.centerAreaMin
        && location.y < screenHeight * Constants.centerAreaMax

      if isCenterArea {
        return .center
      } else if isTopArea || (isMiddleArea && isLeftArea) {
        return .topLeft
      } else {
        return .bottomRight
      }
    }

    /// Handles center tap to toggle controls
    private func handleCenterTap(collectionView: UICollectionView) {
      isHandlingCenterTap = true
      savedScrollOffset = collectionView.contentOffset.y
      onCenterTap?()

      executeAfterDelay(Constants.centerTapHandlingDelay) { [weak self] in
        self?.isHandlingCenterTap = false
      }
    }

    /// Scrolls up
    private func scrollUp(collectionView: UICollectionView, screenHeight: CGFloat) {
      let currentOffset = collectionView.contentOffset.y
      let scrollAmount = screenHeight * Constants.scrollAmountMultiplier
      let targetOffset = max(currentOffset - scrollAmount, 0)
      collectionView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: true)
    }

    /// Scrolls down
    private func scrollDown(collectionView: UICollectionView, screenHeight: CGFloat) {
      let currentOffset = collectionView.contentOffset.y
      let scrollAmount = screenHeight * Constants.scrollAmountMultiplier
      let targetOffset = min(
        currentOffset + scrollAmount,
        collectionView.contentSize.height - screenHeight
      )
      collectionView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: true)
    }
  }
}

// MARK: - Custom Layout

class WebtoonLayout: UICollectionViewFlowLayout {
  override func prepare() {
    super.prepare()
    scrollDirection = .vertical
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
    sectionInset = .zero
  }
}

// MARK: - Custom Cell

class WebtoonPageCell: UICollectionViewCell {
  private let imageView = SDAnimatedImageView()
  private let loadingIndicator = UIActivityIndicatorView(style: .medium)
  private var pageIndex: Int = -1
  private var loadImage: ((Int) async -> Void)?
  private var pageWidth: CGFloat = 0
  private var frameObserver: NSKeyValueObservation?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    contentView.backgroundColor = .black

    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .black
    imageView.clipsToBounds = false
    imageView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)

    frameObserver = imageView.observe(\.frame, options: [.new]) { [weak self] imageView, _ in
      guard let self = self, self.pageWidth > 0 else { return }
      let currentWidth = imageView.frame.width
      // Correct frame immediately if width is wrong - use very small threshold
      if currentWidth > 0 && abs(currentWidth - self.pageWidth) > 0.1 {
        // Force update immediately on main thread
        self.forceUpdateFrame()
      }
    }

    loadingIndicator.color = .white
    loadingIndicator.hidesWhenStopped = true
    contentView.addSubview(loadingIndicator)
  }

  func configure(
    pageIndex: Int, image: UIImage?, loadImage: @escaping (Int) async -> Void
  ) {
    self.pageIndex = pageIndex
    self.loadImage = loadImage

    if pageWidth > 0 {
      forceUpdateFrame()
    }

    imageView.image = nil
    imageView.alpha = 0.0
    loadingIndicator.startAnimating()
  }

  func setPageWidth(_ width: CGFloat) {
    pageWidth = width
    if pageWidth > 0 {
      forceUpdateFrame()
    }
  }

  func updateFrameWithAsyncFallback() {
    forceUpdateFrame()
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.pageWidth > 0 else { return }
      self.forceUpdateFrame()
    }
  }

  func setImageURL(_ url: URL, imageSize: CGSize?, pageWidth: CGFloat) {
    self.pageWidth = pageWidth
    forceUpdateFrame()
    loadingIndicator.stopAnimating()

    imageView.sd_setImage(
      with: url,
      placeholderImage: nil,
      options: [.retryFailed, .scaleDownLargeImages],
      context: [
        .imageScaleDownLimitBytes: 50 * 1024 * 1024
      ],
      progress: nil,
      completed: { [weak self] image, error, cacheType, imageURL in
        guard let self = self else { return }

        if error != nil {
          self.imageView.image = nil
          self.imageView.alpha = 0.0
          self.loadingIndicator.stopAnimating()
        } else if image != nil {
          self.loadingIndicator.stopAnimating()
          // Force update frame multiple times after image is set
          // SDWebImage may change frame during/after image display
          self.forceUpdateFrame()
          self.setNeedsLayout()
          self.layoutIfNeeded()
          self.forceUpdateFrame()

          // Update frame asynchronously to catch any delayed changes
          DispatchQueue.main.async { [weak self] in
            guard let self = self, self.pageWidth > 0 else { return }
            self.forceUpdateFrame()
          }

          UIView.animate(withDuration: 0.2) {
            self.imageView.alpha = 1.0
          } completion: { _ in
            // One more update after animation completes
            self.forceUpdateFrame()
          }
        }
      }
    )
  }

  func forceUpdateFrame() {
    guard pageWidth > 0 else { return }

    // Width must ALWAYS be pageWidth, never depend on bounds or any other value
    let targetWidth = pageWidth

    // Height: use bounds if available, otherwise keep current height
    let bounds = contentView.bounds
    let cellBounds = self.bounds
    let targetHeight: CGFloat
    if bounds.height > 0 {
      targetHeight = bounds.height
    } else if cellBounds.height > 0 {
      targetHeight = cellBounds.height
    } else {
      // If no bounds available, keep current height
      targetHeight = imageView.frame.height > 0 ? imageView.frame.height : 0
    }

    // Only update if we have valid dimensions
    guard targetHeight > 0 else { return }

    let newFrame = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

    // Only set frame if it's different
    if imageView.frame != newFrame {
      imageView.frame = newFrame
    }

    // Also set bounds directly as a backup to ensure width is correct
    if abs(imageView.bounds.width - targetWidth) > 0.1 {
      imageView.bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
    }

    loadingIndicator.center = CGPoint(x: targetWidth / 2, y: targetHeight / 2)
  }

  func showError() {
    imageView.image = nil
    imageView.alpha = 0.0
    loadingIndicator.stopAnimating()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if pageWidth > 0 {
      forceUpdateFrame()
      // Also update asynchronously to catch any delayed bounds updates
      DispatchQueue.main.async { [weak self] in
        guard let self = self, self.pageWidth > 0 else { return }
        self.forceUpdateFrame()
      }
    }
  }

  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    if pageWidth > 0 {
      forceUpdateFrame()
      // Also update asynchronously to catch any delayed bounds updates
      DispatchQueue.main.async { [weak self] in
        guard let self = self, self.pageWidth > 0 else { return }
        self.forceUpdateFrame()
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.sd_cancelCurrentImageLoad()
    imageView.image = nil
    imageView.alpha = 0.0
    loadingIndicator.stopAnimating()
    loadingIndicator.isHidden = true
    pageIndex = -1
    loadImage = nil
    // Don't reset pageWidth - keep it so reused cells maintain correct width
    // Force update frame to ensure correct width is maintained
    if pageWidth > 0 {
      forceUpdateFrame()
    }
  }

  deinit {
    frameObserver?.invalidate()
  }
}

// MARK: - Footer Cell

class WebtoonFooterCell: UICollectionViewCell {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    contentView.backgroundColor = .black
  }
}
