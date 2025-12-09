//
//  Toolbox
//
//  Copyright (C) 2025-2026 Sector 42 Limited
//  All Rights Reserved
//

import AppKit
import SwiftUI

@main
struct ToolboxApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    // Keep a Settings scene so the SwiftUI App lifecycle is satisfied.
    Settings {
      EmptyView()
    }
  }
}
