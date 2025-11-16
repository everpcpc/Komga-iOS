//
//  ReaderViewModel.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import OSLog
import SwiftUI

enum ReadingDirection: CaseIterable, Hashable {
  case ltr
  case rtl
  case vertical
  case webtoon

  static func fromString(_ direction: String) -> ReadingDirection {
    switch direction.uppercased() {
    case "LEFT_TO_RIGHT":
      return .ltr
    case "RIGHT_TO_LEFT":
      return .rtl
    case "VERTICAL":
      return .vertical
    case "WEBTOON":
      return .webtoon
    default:
      return .ltr
    }
  }

  var displayName: String {
    switch self {
    case .ltr:
      return "LTR"
    case .rtl:
      return "RTL"
    case .vertical:
      return "Vertical"
    case .webtoon:
      return "Webtoon"
    }
  }

  var icon: String {
    if #available(iOS 18.0, *) {
      switch self {
      case .ltr:
        return "inset.filled.trailinghalf.arrow.trailing.rectangle"
      case .rtl:
        return "inset.filled.leadinghalf.arrow.leading.rectangle"
      case .vertical:
        return "rectangle.portrait.bottomhalf.filled"
      case .webtoon:
        return "arrow.up.and.down.square"
      }
    } else {
      switch self {
      case .ltr:
        return "rectangle.trailinghalf.inset.filled.arrow.trailing"
      case .rtl:
        return "rectangle.leadinghalf.inset.filled.arrow.leading"
      case .vertical:
        return "rectangle.portrait.bottomhalf.filled"
      case .webtoon:
        return "arrow.up.and.down.square"
      }
    }
  }
}

@MainActor
@Observable
class ReaderViewModel {
  var pages: [BookPage] = []
  var currentPage = 0
  var isLoading = false
  var errorMessage: String?
  var pageImageCache: ImageCache
  var readingDirection: ReadingDirection = .ltr

  private let bookService = BookService.shared
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Komga", category: "ReaderViewModel")
  /// Current book ID for API calls and cache access
  var bookId: String = ""

  /// Track ongoing download tasks to prevent duplicate downloads for the same page
  private var downloadingTasks: [Int: Task<URL?, Never>] = [:]

  init() {
    self.pageImageCache = ImageCache()
  }

  func loadPages(bookId: String, initialPage: Int? = nil) async {
    self.bookId = bookId
    isLoading = true
    errorMessage = nil

    // Cancel all ongoing download tasks when loading a new book
    for (_, task) in downloadingTasks {
      task.cancel()
    }
    downloadingTasks.removeAll()

    do {
      pages = try await bookService.getBookPages(id: bookId)

      // Set initial page if provided
      // Note: API page numbers are 1-based, but array indices are 0-based
      if let initialPage = initialPage {
        if let pageIndex = pages.firstIndex(where: { $0.number == initialPage }) {
          currentPage = pageIndex
        }
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  /// Get page image file URL from disk cache, or download and cache if not available
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Local file URL if available, nil if download failed
  /// - Note: Prevents duplicate downloads by tracking ongoing tasks
  func getPageImageFileURL(pageIndex: Int) async -> URL? {
    guard pageIndex >= 0 && pageIndex < pages.count else {
      logger.warning(
        "⚠️ Invalid page index: \(pageIndex) (total pages: \(self.pages.count)) for book \(self.bookId)"
      )
      return nil
    }

    guard !bookId.isEmpty else {
      logger.warning("⚠️ Book ID is empty, cannot load page image")
      return nil
    }

    // Check if already cached
    if let cachedFileURL = getCachedImageFileURL(pageIndex: pageIndex) {
      logger.debug(
        "✅ Using cached image for page \(self.pages[pageIndex].number) (index: \(pageIndex)) for book \(self.bookId)"
      )
      return cachedFileURL
    }

    // Check if there's already a download task for this page
    if let existingTask = downloadingTasks[pageIndex] {
      logger.debug(
        "⏳ Waiting for existing download task for page \(self.pages[pageIndex].number) (index: \(pageIndex)) for book \(self.bookId)"
      )
      // Wait for the existing task to complete
      if let result = await existingTask.value {
        return result
      }
      // If the existing task returned nil, check cache again
      // (the file might have been saved by another concurrent request)
      if let cachedFileURL = getCachedImageFileURL(pageIndex: pageIndex) {
        return cachedFileURL
      }
      return nil
    }

    // Not cached and no existing task, create a new download task
    let apiPageNumber = pages[pageIndex].number
    let downloadTask = Task<URL?, Never> {
      logger.info(
        "📥 Downloading page \(apiPageNumber) (index: \(pageIndex)) for book \(self.bookId)")

      do {
        let data = try await bookService.getBookPage(bookId: self.bookId, page: apiPageNumber)

        let dataSize = ByteCountFormatter.string(
          fromByteCount: Int64(data.count), countStyle: .binary)
        logger.info(
          "✅ Downloaded page \(apiPageNumber) successfully (\(dataSize)) for book \(self.bookId)")

        // Save raw image data to disk cache (decoding is handled by SDWebImage)
        await pageImageCache.storeImageData(data, forKey: pageIndex, bookId: self.bookId)

        // Return the cached file URL
        if let fileURL = getCachedImageFileURL(pageIndex: pageIndex) {
          logger.debug("💾 Saved page \(apiPageNumber) to disk cache for book \(self.bookId)")
          return fileURL
        } else {
          logger.error(
            "❌ Failed to get file URL after saving page \(apiPageNumber) to cache for book \(self.bookId)"
          )
          return nil
        }
      } catch {
        // Download failed
        logger.error(
          "❌ Failed to download page \(apiPageNumber) (index: \(pageIndex)) for book \(self.bookId): \(error.localizedDescription)"
        )
        return nil
      }
    }

    // Store the task
    downloadingTasks[pageIndex] = downloadTask

    // Wait for the task to complete
    let result = await downloadTask.value

    // Remove the task from the dictionary
    downloadingTasks.removeValue(forKey: pageIndex)

    return result
  }

  /// Get cached image file URL from disk cache
  /// - Parameter pageIndex: Zero-based page index
  /// - Returns: Local file URL if the cached file exists, nil otherwise
  private func getCachedImageFileURL(pageIndex: Int) -> URL? {
    // Construct the file path: CacheDirectory/KomgaImageCache/{bookId}/page_{index}.data
    let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let diskCacheURL = cacheDir.appendingPathComponent("KomgaImageCache", isDirectory: true)
    let bookCacheDir = diskCacheURL.appendingPathComponent(bookId, isDirectory: true)
    let fileURL = bookCacheDir.appendingPathComponent("page_\(pageIndex).data")

    // Verify file exists before returning URL
    if FileManager.default.fileExists(atPath: fileURL.path) {
      return fileURL
    }
    return nil
  }

  /// Preload pages around the current page for smoother scrolling
  /// Preloads 1 page before and 3 pages after the current page
  func preloadPages() async {
    let preloadBefore = max(0, currentPage - 1)
    let preloadAfter = min(currentPage + 3, pages.count)
    let pagesToPreload = Array(preloadBefore..<preloadAfter)

    // Load pages concurrently for better performance
    await withTaskGroup(of: Void.self) { group in
      for pageIndex in pagesToPreload {
        // Only preload if not already cached
        if !pageImageCache.hasImage(forKey: pageIndex, bookId: bookId) {
          group.addTask {
            _ = await self.getPageImageFileURL(pageIndex: pageIndex)
          }
        }
      }
    }
  }

  /// Preload pages around a specific page index
  /// Used when pages appear in TabView or other paginated views
  /// Preloads 1 page before and 3 pages after the specified page
  func preloadPagesAround(pageIndex: Int) async {
    let preloadBefore = max(0, pageIndex - 1)
    let preloadAfter = min(pageIndex + 3, pages.count)
    let pagesToPreload = Array(preloadBefore..<preloadAfter)

    // Load pages concurrently for better performance
    await withTaskGroup(of: Void.self) { group in
      for index in pagesToPreload {
        // Only preload if not already cached
        if !pageImageCache.hasImage(forKey: index, bookId: bookId) {
          group.addTask {
            _ = await self.getPageImageFileURL(pageIndex: index)
          }
        }
      }
    }
  }

  /// Update reading progress on the server
  /// Uses API page number (1-based) instead of array index (0-based)
  func updateProgress() async {
    guard !bookId.isEmpty else { return }
    guard currentPage >= 0 && currentPage < pages.count else { return }

    let completed = currentPage >= pages.count - 1
    let apiPageNumber = pages[currentPage].number

    do {
      try await bookService.updateReadProgress(
        bookId: bookId,
        page: apiPageNumber,
        completed: completed
      )
    } catch {
      // Progress updates are non-critical, fail silently
    }
  }

  /// Convert display index to actual page index based on reading direction
  /// - Parameter displayIndex: The index as displayed to the user
  /// - Returns: The actual page index in the pages array
  func displayIndexToPageIndex(_ displayIndex: Int) -> Int {
    switch readingDirection {
    case .ltr:
      return displayIndex
    case .rtl:
      return pages.count - 1 - displayIndex
    case .vertical, .webtoon:
      return displayIndex
    }
  }

  /// Convert actual page index to display index based on reading direction
  /// - Parameter pageIndex: The actual page index in the pages array
  /// - Returns: The index as displayed to the user
  func pageIndexToDisplayIndex(_ pageIndex: Int) -> Int {
    switch readingDirection {
    case .ltr:
      return pageIndex
    case .rtl:
      return pages.count - 1 - pageIndex
    case .vertical, .webtoon:
      return pageIndex
    }
  }
}
