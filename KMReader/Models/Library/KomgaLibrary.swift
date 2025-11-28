//
//  KomgaLibrary.swift
//  KMReader
//
//  Created by Komga iOS Client
//

import Foundation
import SwiftData

@Model
final class KomgaLibrary {
  @Attribute(.unique) var id: UUID
  var instanceId: String
  var libraryId: String
  var name: String
  var createdAt: Date

  init(
    id: UUID = UUID(),
    instanceId: String,
    libraryId: String,
    name: String,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.instanceId = instanceId
    self.libraryId = libraryId
    self.name = name
    self.createdAt = createdAt
  }
}
