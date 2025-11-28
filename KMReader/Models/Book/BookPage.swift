//
//  BookPage.swift
//  Komga
//
//  Created by Komga iOS Client
//

import Foundation
import UniformTypeIdentifiers

struct BookPage: Codable, Identifiable, Sendable {
  let number: Int
  let fileName: String
  let mediaType: String
  let width: Int?
  let height: Int?
  let sizeBytes: Int64?
  let size: String
  let downloadURL: URL?

  var id: Int { number }

  /// Best-effort UTType detection using file extension first, then MIME type.
  var detectedUTType: UTType? {
    let fileExtension = (fileName as NSString).pathExtension.lowercased()
    if !fileExtension.isEmpty, let type = UTType(filenameExtension: fileExtension) {
      return type
    }

    let mimeType =
      mediaType.split(separator: ";").first?.trimmingCharacters(in: .whitespaces)
      ?? mediaType
    return UTType(mimeType: mimeType)
  }

  var isPortrait: Bool {
    guard let width = width, let height = height else { return false }
    return height > width
  }
}
