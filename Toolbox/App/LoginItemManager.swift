//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import Foundation
import ServiceManagement

final class LoginItemManager {
  static let shared = LoginItemManager()

  private init() {}

  var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  func toggle() throws {
    if isEnabled {
      try disable()
    } else {
      try enable()
    }
  }

  private func enable() throws {
    try SMAppService.mainApp.register()
  }

  private func disable() throws {
    try SMAppService.mainApp.unregister()
  }
}
