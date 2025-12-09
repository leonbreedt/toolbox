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

  // Retain the welcome window via a controller to avoid premature teardown
  private var welcomeWindowController: NSWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupTools()
    statusItemController = StatusItemController(
      registry: registry,
      presenter: presenter
    )
    checkFirstLaunch()
  }

  private func setupTools() {
    registry.registerAll([
      JWTDecoderTool()
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
    if let controller = welcomeWindowController {
      controller.showWindow(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = "Welcome to Toolbox"
    window.center()
    window.isReleasedWhenClosed = false

    let controller = NSWindowController(window: window)
    self.welcomeWindowController = controller

    let hosting = NSHostingController(
      rootView: WelcomeView { [weak self] in
        UserDefaults.standard.set(true, forKey: "firstRun")
        DispatchQueue.main.async {
          self?.welcomeWindowController?.close()
        }
      }
      .frame(width: 500, height: 450)
    )
    window.contentViewController = hosting

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      self?.welcomeWindowController = nil
    }

    controller.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
