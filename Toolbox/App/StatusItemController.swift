//
//  Toolbox
//
//  Copyright (C) 2025-2026 Sector 42 Limited
//  All Rights Reserved
//

import AppKit
import SwiftUI

final class StatusItemController: NSObject, NSMenuDelegate {
  private let registry: ToolRegistry
  private let presenter: ToolPresenter

  private let statusItem: NSStatusItem
  private let menu = NSMenu()

  private let menuMinimumWidth: CGFloat = 240

  private var aboutWindowController: NSWindowController?

  init(registry: ToolRegistry, presenter: ToolPresenter) {
    self.registry = registry
    self.presenter = presenter
    self.statusItem = NSStatusBar.system.statusItem(
      withLength: NSStatusItem.variableLength
    )

    super.init()

    configureStatusItem()
    configureMenu()
  }

  private func configureStatusItem() {
    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: "wrench.and.screwdriver",
        accessibilityDescription: "Toolbox"
      )
      button.image?.isTemplate = true
    }
  }

  private func configureMenu() {
    menu.delegate = self
    menu.autoenablesItems = false
    menu.minimumWidth = menuMinimumWidth
    statusItem.menu = menu
  }

  func menuWillOpen(_ menu: NSMenu) {
    rebuildMenu()
  }

  private func rebuildMenu() {
    menu.removeAllItems()

    let headingItem = NSMenuItem()
    headingItem.isEnabled = false
    headingItem.attributedTitle = NSAttributedString(
      string: "Toolbox",
      attributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .bold)
      ]
    )
    menu.addItem(headingItem)
    menu.addItem(.separator())

    let categoriesWithTools = ToolCategory.allCases.filter { category in
      guard let tools = registry.toolsByCategory[category] else { return false }
      return !tools.isEmpty
    }

    for (index, category) in categoriesWithTools.enumerated() {
      let categoryItem = NSMenuItem()

      categoryItem.isEnabled = false
      categoryItem.attributedTitle = NSAttributedString(
        string: category.displayName,
        attributes: [
          .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
          .foregroundColor: NSColor.secondaryLabelColor,
        ]
      )
      menu.addItem(categoryItem)

      guard let tools = registry.toolsByCategory[category] else {
        continue
      }

      for tool in tools {
        let item = NSMenuItem(
          title: tool.name,
          action: #selector(didSelectTool(_:)),
          keyEquivalent: ""
        )
        item.target = self
        item.representedObject = tool.id
        if let image = NSImage(
          systemSymbolName: tool.icon,
          accessibilityDescription: nil
        ) {
          image.isTemplate = true
          item.image = image
        }
        menu.addItem(item)
      }

      if index < categoriesWithTools.count - 1 {
        menu.addItem(.separator())
      }
    }

    if !categoriesWithTools.isEmpty {
      menu.addItem(.separator())
    }

    let aboutTitle = "About"
    let aboutItem = NSMenuItem(
      title: aboutTitle,
      action: #selector(showAbout),
      keyEquivalent: ""
    )
    aboutItem.target = self
    menu.addItem(aboutItem)

    let quitItem = NSMenuItem(
      title: "Quit",
      action: #selector(quitApp),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)
  }

  private var appDisplayName: String {
    if let name = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleDisplayName"
    ) as? String, !name.isEmpty {
      return name
    }
    if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
      as? String, !name.isEmpty
    {
      return name
    }
    return "Toolbox"
  }

  @objc private func didSelectTool(_ sender: NSMenuItem) {
    guard let toolID = sender.representedObject as? String,
      let tool = registry.tools.first(where: { $0.id == toolID })
    else {
      return
    }
    presenter.present(tool)
  }

  @objc private func showAbout() {
    // If already open, just focus it.
    if let controller = aboutWindowController {
      controller.showWindow(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    // Build the About window.
    let size = NSSize(width: 380, height: 260)
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.center()
    window.title = "About \(appDisplayName)"
    window.isReleasedWhenClosed = false

    let view = AboutView()
    let hosting = NSHostingView(
      rootView: view.frame(minWidth: size.width, minHeight: size.height)
    )
    window.contentView = hosting

    let controller = NSWindowController(window: window)
    aboutWindowController = controller

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      self?.aboutWindowController = nil
    }

    controller.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
