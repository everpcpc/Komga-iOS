//
//  Media.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation

enum MediaProfile: String, Codable {
  case divina = "DIVINA"
  case pdf = "PDF"
  case epub = "EPUB"
}

struct Media: Codable, Equatable {
  let status: String
  let mediaType: String
  let pagesCount: Int
  let comment: String?
  let mediaProfile: MediaProfile?
  let epubDivinaCompatible: Bool?
  let epubIsKepub: Bool?
}
