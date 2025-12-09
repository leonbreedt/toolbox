//
//  Toolbox
//
//  Copyright (C) 2025-2026 Sector 42 Limited
//  All Rights Reserved
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  let registry = ToolRegistry()
  let presenter = ToolPresenter()
  private var statusItemController: StatusItemController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupTools()
    statusItemController = StatusItemController(registry: registry, presenter: presenter)
    checkFirstLaunch()
  }

  private func setupTools() {
    registry.registerAll([
      JWTDecoderTool(),
    ])
  }

  private func checkFirstLaunch() {
    let hasLaunched = UserDefaults.standard.bool(forKey: "firstRun")
    if !hasLaunched {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.showWelcomeWindow()
      }
    }
  }

  private func showWelcomeWindow() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = "Welcome to Toolbox"
    window.center()
    window.contentView = NSHostingView(
      rootView: WelcomeView {
        UserDefaults.standard.set(true, forKey: "firstRun")
        window.close()
      })
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
