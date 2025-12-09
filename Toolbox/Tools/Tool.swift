//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import Foundation
import SwiftUI

@MainActor
protocol Tool: Identifiable {
  var id: String { get }
  var name: String { get }
  var category: ToolCategory { get }
  var icon: String { get }

  var presentationStyle: ToolPresentationStyle { get }

  func makeView(context: ToolContext) -> AnyView
}

enum ToolPresentationStyle {
  case popover(size: CGSize)
  case window(size: CGSize, resizable: Bool)
}

enum ToolCategory: String, CaseIterable {
  case utilities
  case development
  case productivity

  var displayName: String {
    switch self {
    case .utilities: return "Utilities"
    case .development: return "Development"
    case .productivity: return "Productivity"
    }
  }
}

@MainActor
final class ToolContext {
  private let toolID: String

  init(toolID: String) {
    self.toolID = toolID
  }

  private func makeKey(_ key: String) -> String {
    return "tool.\(toolID).\(key)"
  }

  func save<T: Codable>(_ value: T, forKey key: String) {
    let fullKey = makeKey(key)
    if let encoded = try? JSONEncoder().encode(value) {
      UserDefaults.standard.set(encoded, forKey: fullKey)
    }
  }

  func load<T: Codable>(forKey key: String) -> T? {
    let fullKey = makeKey(key)
    guard let data = UserDefaults.standard.data(forKey: fullKey) else {
      return nil
    }
    return try? JSONDecoder().decode(T.self, from: data)
  }

  func remove(forKey key: String) {
    let fullKey = makeKey(key)
    UserDefaults.standard.removeObject(forKey: fullKey)
  }
}
