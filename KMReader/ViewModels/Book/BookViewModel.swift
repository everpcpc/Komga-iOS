//
//  BookViewModel.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftUI

@MainActor
@Observable
class BookViewModel {
  var books: [Book] = []
  var currentBook: Book?
  var isLoading = false

  private let bookService = BookService.shared
  private var currentPage = 0
  private var hasMorePages = true
  private var currentSeriesId: String?
  private var currentSeriesBrowseOpts: BookBrowseOptions?
  private var currentBrowseState: BookBrowseOptions?
  private var currentBrowseSort: String?
  private var currentBrowseSearch: String = ""

  func loadBooks(seriesId: String, browseOpts: BookBrowseOptions, refresh: Bool = true) async {
    // Check if we're loading the same series with same options
    let isSameSeries = currentSeriesId == seriesId && currentSeriesBrowseOpts == browseOpts

    // Only clear books if it's a different series or forced refresh
    let shouldClear = refresh || !isSameSeries

    currentSeriesId = seriesId
    currentSeriesBrowseOpts = browseOpts
    currentPage = 0
    hasMorePages = true

    // Preserve existing books if refreshing the same series to avoid UI flicker
    if shouldClear {
      books = []
    }
    isLoading = true

    do {
      let page = try await bookService.getBooks(
        seriesId: seriesId, page: 0, size: 50, browseOpts: browseOpts)
      withAnimation {
        books = page.content
      }
      hasMorePages = !page.last
      currentPage = 1
    } catch {
      ErrorManager.shared.alert(error: error)
      // If error occurred and we preserved old data, keep it
      // If we cleared data and error occurred, books will remain empty
    }

    isLoading = false
  }

  func loadMoreBooks(seriesId: String) async {
    guard hasMorePages && !isLoading && seriesId == currentSeriesId,
      let browseOpts = currentSeriesBrowseOpts
    else { return }

    isLoading = true

    do {
      let page = try await bookService.getBooks(
        seriesId: seriesId, page: currentPage, size: 50, browseOpts: browseOpts)
      withAnimation {
        books.append(contentsOf: page.content)
      }
      hasMorePages = !page.last
      currentPage += 1
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }

  // Refresh current books list smoothly without clearing existing data
  func refreshCurrentBooks() async {
    guard let seriesId = currentSeriesId,
      let browseOpts = currentSeriesBrowseOpts
    else { return }
    await loadBooks(seriesId: seriesId, browseOpts: browseOpts, refresh: false)
  }

  func loadBook(id: String) async {
    isLoading = true

    do {
      currentBook = try await bookService.getBook(id: id)
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }

  func loadBooksOnDeck(libraryId: String = "") async {
    isLoading = true

    do {
      let page = try await bookService.getBooksOnDeck(libraryId: libraryId, size: 20)
      withAnimation {
        books = page.content
      }
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }

  func updatePageReadProgress(bookId: String, page: Int, completed: Bool = false) async {
    do {
      try await bookService.updatePageReadProgress(bookId: bookId, page: page, completed: completed)
      if currentBook?.id == bookId {
        await loadBook(id: bookId)
      }
    } catch {
      ErrorManager.shared.alert(error: error)
    }
  }

  func markAsRead(bookId: String) async {
    do {
      try await bookService.markAsRead(bookId: bookId)
      let updatedBook = try await bookService.getBook(id: bookId)
      if let index = books.firstIndex(where: { $0.id == bookId }) {
        books[index] = updatedBook
      }
      if currentBook?.id == bookId {
        currentBook = updatedBook
      }
      await MainActor.run {
        ErrorManager.shared.notify(message: "Marked as read")
      }
    } catch {
      ErrorManager.shared.alert(error: error)
    }
  }

  func markAsUnread(bookId: String) async {
    do {
      try await bookService.markAsUnread(bookId: bookId)
      let updatedBook = try await bookService.getBook(id: bookId)
      if let index = books.firstIndex(where: { $0.id == bookId }) {
        books[index] = updatedBook
      }
      if currentBook?.id == bookId {
        currentBook = updatedBook
      }
      await MainActor.run {
        ErrorManager.shared.notify(message: "Marked as unread")
      }
    } catch {
      ErrorManager.shared.alert(error: error)
    }
  }

  func loadRecentlyReadBooks(libraryId: String = "", refresh: Bool = false) async {
    if refresh {
      currentPage = 0
      hasMorePages = true
    } else {
      guard hasMorePages else { return }
    }

    guard !isLoading else { return }

    isLoading = true

    do {
      let page = try await bookService.getRecentlyReadBooks(
        libraryId: libraryId,
        page: currentPage,
        size: 20
      )

      withAnimation {
        if refresh {
          books = page.content
        } else {
          books.append(contentsOf: page.content)
        }
      }

      hasMorePages = !page.last
      currentPage += 1
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }

  func loadBrowseBooks(
    browseOpts: BookBrowseOptions, searchText: String = "", refresh: Bool = false
  )
    async
  {
    let libraryId = AppConfig.selectedLibraryId
    let sort = browseOpts.sortString
    let paramsChanged =
      currentBrowseState?.readStatusFilter != browseOpts.readStatusFilter
      || currentBrowseSort != sort
      || currentBrowseSearch != searchText

    let shouldReset = refresh || paramsChanged

    if shouldReset {
      currentPage = 0
      hasMorePages = true
      currentBrowseState = browseOpts
      currentBrowseSort = sort
      currentBrowseSearch = searchText
    }

    guard hasMorePages && !isLoading else { return }

    isLoading = true

    do {
      let condition = BookSearch.buildCondition(
        libraryId: libraryId.isEmpty ? nil : libraryId,
        readStatus: browseOpts.readStatusFilter.toReadStatus()
      )

      let search = BookSearch(
        condition: condition,
        fullTextSearch: searchText.isEmpty ? nil : searchText
      )
      let page = try await bookService.getBooksList(
        search: search,
        page: currentPage,
        size: 20,
        sort: sort
      )

      withAnimation {
        if shouldReset {
          books = page.content
        } else {
          books.append(contentsOf: page.content)
        }
      }

      hasMorePages = !page.last
      currentPage += 1
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }

  func loadReadListBooks(
    readListId: String,
    browseOpts: BookBrowseOptions,
    refresh: Bool = false
  ) async {
    if refresh {
      currentPage = 0
      hasMorePages = true
    } else {
      guard hasMorePages && !isLoading else { return }
    }

    isLoading = true

    do {
      let page = try await ReadListService.shared.getReadListBooks(
        readListId: readListId,
        page: currentPage,
        size: 50,
        browseOpts: browseOpts
      )

      withAnimation {
        if refresh {
          books = page.content
        } else {
          books.append(contentsOf: page.content)
        }
      }

      hasMorePages = !page.last
      currentPage += 1
    } catch {
      ErrorManager.shared.alert(error: error)
    }

    isLoading = false
  }
}
