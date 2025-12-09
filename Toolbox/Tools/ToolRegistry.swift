//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import Foundation
import SwiftUI

@MainActor
final class ToolRegistry {
  private(set) var tools: [any Tool] = []

  var toolsByCategory: [ToolCategory: [any Tool]] {
    Dictionary(grouping: tools, by: { $0.category })
  }

  func register(_ tool: any Tool) {
    tools.append(tool)
  }

  func registerAll(_ tools: [any Tool]) {
    self.tools.append(contentsOf: tools)
  }
}
