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
  var errorMessage: String?

  private let bookService = BookService.shared
  private var currentPage = 0
  private var hasMorePages = true
  private var currentSeriesId: String?
  private var currentSort: String = "metadata.numberSort,asc"

  func loadBooks(seriesId: String, sort: String = "metadata.numberSort,asc") async {
    currentSeriesId = seriesId
    currentSort = sort
    currentPage = 0
    books = []
    hasMorePages = true
    isLoading = true
    errorMessage = nil

    do {
      let page = try await bookService.getBooks(seriesId: seriesId, page: 0, size: 50, sort: sort)
      withAnimation {
        books = page.content
      }
      hasMorePages = !page.last
      currentPage = 1
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadMoreBooks(seriesId: String) async {
    guard hasMorePages && !isLoading && seriesId == currentSeriesId else { return }

    isLoading = true
    errorMessage = nil

    do {
      let page = try await bookService.getBooks(
        seriesId: seriesId, page: currentPage, size: 50, sort: currentSort)
      withAnimation {
        books.append(contentsOf: page.content)
      }
      hasMorePages = !page.last
      currentPage += 1
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadBook(id: String) async {
    isLoading = true
    errorMessage = nil

    do {
      currentBook = try await bookService.getBook(id: id)
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadBooksOnDeck(libraryId: String = "") async {
    isLoading = true
    errorMessage = nil

    do {
      let page = try await bookService.getBooksOnDeck(libraryId: libraryId, size: 20)
      books = page.content
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func updateReadProgress(bookId: String, page: Int, completed: Bool = false) async {
    do {
      try await bookService.updateReadProgress(bookId: bookId, page: page, completed: completed)
      if currentBook?.id == bookId {
        await loadBook(id: bookId)
      }
    } catch {
      errorMessage = error.localizedDescription
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
    } catch {
      errorMessage = error.localizedDescription
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
    } catch {
      errorMessage = error.localizedDescription
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
    errorMessage = nil

    do {
      let page = try await bookService.getRecentlyReadBooks(
        libraryId: libraryId,
        page: currentPage,
        size: 20
      )

      if refresh {
        books = page.content
      } else {
        books.append(contentsOf: page.content)
      }

      hasMorePages = !page.last
      currentPage += 1
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}
