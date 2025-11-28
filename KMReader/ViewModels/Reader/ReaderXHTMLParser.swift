//
//  ReaderXHTMLParser.swift
//  KMReader
//
//  Created by Komga iOS Client
//

import Foundation

struct ReaderXHTMLImageInfo {
  let url: URL
  let width: Int?
  let height: Int?
  let mediaType: String?
}

enum ReaderXHTMLParser {
  static func firstImageInfo(from data: Data, baseURL: URL) -> ReaderXHTMLImageInfo? {
    guard let html = decodeText(from: data) else { return nil }
    return extractFirstImageInfo(from: html, baseURL: baseURL)
  }

  private static func decodeText(from data: Data) -> String? {
    let encodings: [String.Encoding] = [
      .utf8,
      .utf16,
      .utf16LittleEndian,
      .utf16BigEndian,
      .isoLatin1,
      .windowsCP1252,
    ]

    for encoding in encodings {
      if let string = String(data: data, encoding: encoding) {
        return string
      }
    }
    return nil
  }

  private static func extractFirstImageInfo(from html: String, baseURL: URL)
    -> ReaderXHTMLImageInfo?
  {
    let searchTargets = [
      ("img", "src"),
      ("image", "xlink:href"),
      ("image", "href"),
    ]

    for (tag, attribute) in searchTargets {
      if
        let match = matchTag(named: tag, attribute: attribute, in: html),
        let resolvedURL = URL(string: match.value, relativeTo: baseURL)?.absoluteURL
      {
        let width = parseDimension(attribute: "width", in: match.tag)
        let height = parseDimension(attribute: "height", in: match.tag)
        let explicitType = extractAttribute(named: "type", in: match.tag)
        let normalizedType = ReaderMediaHelper.normalizedMimeType(explicitType)
        return ReaderXHTMLImageInfo(
          url: resolvedURL,
          width: width,
          height: height,
          mediaType: normalizedType.isEmpty ? nil : normalizedType
        )
      }
    }

    return nil
  }

  private static func matchTag(
    named tagName: String,
    attribute: String,
    in html: String
  ) -> TagMatch? {
    let escapedAttribute = NSRegularExpression.escapedPattern(for: attribute)
    let pattern = "<\(tagName)\\b[^>]*\(escapedAttribute)\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>"
    guard let regex = try? NSRegularExpression(
      pattern: pattern,
      options: [.caseInsensitive, .dotMatchesLineSeparators]
    ) else {
      return nil
    }

    let range = NSRange(html.startIndex..., in: html)
    guard let match = regex.firstMatch(in: html, options: [], range: range) else {
      return nil
    }

    guard
      let tagRange = Range(match.range(at: 0), in: html),
      let valueRange = Range(match.range(at: 1), in: html)
    else {
      return nil
    }

    return TagMatch(
      tag: String(html[tagRange]),
      value: String(html[valueRange])
    )
  }

  private static func extractAttribute(named name: String, in tag: String) -> String? {
    let escapedName = NSRegularExpression.escapedPattern(for: name)
    let pattern = "\(escapedName)\\s*=\\s*['\"]([^'\"]+)['\"]"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return nil
    }
    let range = NSRange(tag.startIndex..., in: tag)
    guard let match = regex.firstMatch(in: tag, options: [], range: range) else {
      return nil
    }
    guard let valueRange = Range(match.range(at: 1), in: tag) else {
      return nil
    }
    return String(tag[valueRange])
  }

  private static func parseDimension(attribute: String, in tag: String) -> Int? {
    guard let rawValue = extractAttribute(named: attribute, in: tag) else { return nil }
    let filtered = rawValue.filter { "0123456789.".contains($0) }
    guard let doubleValue = Double(filtered) else {
      return nil
    }
    return Int(doubleValue.rounded())
  }

  private struct TagMatch {
    let tag: String
    let value: String
  }
}
