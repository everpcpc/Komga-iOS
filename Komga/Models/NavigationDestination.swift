//
//  NavigationDestination.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

enum NavigationDestination: Hashable {
  case seriesDetail(seriesId: String)
  case bookDetail(bookId: String)
}
