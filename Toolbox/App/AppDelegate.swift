//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import AppKit
import Sparkle
import SwiftUI

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
  let registry = ToolRegistry()
  let presenter = ToolPresenter()
  private var statusItemController: StatusItemController!
  private let updaterController: SPUStandardUpdaterController

  private var welcomeWindowController: NSWindowController?

  override init() {
    updaterController = SPUStandardUpdaterController(
      startingUpdater: true,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
    super.init()
  }

  static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
  }

  func applicationWillFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupMainMenu()
    setupTools()

    statusItemController = StatusItemController(
      registry: registry,
      presenter: presenter,
      updater: updaterController.updater
    )

    checkFirstLaunch()
  }

  private func setupTools() {
    registry.registerAll([
      JWTDecoderTool()
    ])
  }

  private func setupMainMenu() {
    // Needed for status-bar only applications (agents).
    let mainMenu = NSMenu()

    let appMenuItem = NSMenuItem()
    mainMenu.addItem(appMenuItem)
    let appMenu = NSMenu(title: "App")
    let quitItem = NSMenuItem(
      title: "Quit",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    appMenu.addItem(quitItem)
    appMenuItem.submenu = appMenu

    let editMenuItem = NSMenuItem()
    mainMenu.addItem(editMenuItem)
    let editMenu = NSMenu(title: "Edit")

    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    editMenu.addItem(.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(
      withTitle: "Delete", action: #selector(NSResponder.deleteBackward(_:)),
      keyEquivalent: String())
    editMenu.addItem(
      withTitle: "Select All", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a")

    editMenuItem.submenu = editMenu

    NSApp.mainMenu = mainMenu
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

    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true

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
