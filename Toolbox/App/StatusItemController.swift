//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import AppKit
import Sparkle
import SwiftUI

final class StatusItemController: NSObject, NSMenuDelegate {
  private let registry: ToolRegistry
  private let presenter: ToolPresenter
  private weak var updater: SPUUpdater?

  private let statusItem: NSStatusItem
  private let menu = NSMenu()

  private let menuMinimumWidth: CGFloat = 240

  init(registry: ToolRegistry, presenter: ToolPresenter, updater: SPUUpdater? = nil) {
    self.registry = registry
    self.presenter = presenter
    self.updater = updater
    self.statusItem = NSStatusBar.system.statusItem(
      withLength: NSStatusItem.variableLength
    )

    super.init()

    configureStatusItem()
    configureMenu()

    rebuildMenu()
  }

  private func configureStatusItem() {
    guard let button = statusItem.button else {
      return
    }

    if let image = NSImage(
      systemSymbolName: "wrench.and.screwdriver",
      accessibilityDescription: "Toolbox"
    ) {
      button.image = image
      button.image?.isTemplate = true
    }

    statusItem.isVisible = true
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
    headingItem.view = makeHeadingView(title: "Toolbox")
    headingItem.isEnabled = false
    menu.addItem(headingItem)
    menu.addItem(.separator())

    let categoriesWithTools = ToolCategory.allCases.filter { category in
      guard let tools = registry.toolsByCategory[category] else { return false }
      return !tools.isEmpty
    }

    for (index, category) in categoriesWithTools.enumerated() {
      let categoryItem = NSMenuItem()
      categoryItem.view = makeCategoryHeadingView(title: category.displayName)
      categoryItem.isEnabled = false
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

    let checkForUpdatesItem = NSMenuItem(
      title: "Check for Updates…",
      action: #selector(checkForUpdates),
      keyEquivalent: ""
    )
    checkForUpdatesItem.target = self
    menu.addItem(checkForUpdatesItem)

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

  private func makeHeadingView(title: String) -> NSView {
    let label = NSTextField(labelWithString: title)
    label.font = NSFont.systemFont(ofSize: 13, weight: .bold)
    label.textColor = .labelColor
    label.alignment = .left
    label.lineBreakMode = .byTruncatingTail

    let container = NSView(
      frame: NSRect(x: 0, y: 0, width: Int(menuMinimumWidth), height: 22)
    )
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(
        equalTo: container.leadingAnchor,
        constant: 12
      ),
      label.trailingAnchor.constraint(
        lessThanOrEqualTo: container.trailingAnchor,
        constant: -8
      ),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      container.heightAnchor.constraint(equalToConstant: 22),
    ])

    return container
  }

  private func makeCategoryHeadingView(title: String) -> NSView {
    let standardLeadingInset: CGFloat = 18
    let rowHeight: CGFloat = 22

    let label = NSTextField(labelWithString: title)
    label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
    label.textColor = .secondaryLabelColor
    label.alignment = .left
    label.lineBreakMode = .byTruncatingTail

    let container = NSView(
      frame: NSRect(
        x: 0,
        y: 0,
        width: Int(menuMinimumWidth),
        height: Int(rowHeight)
      )
    )
    label.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(
        equalTo: container.leadingAnchor,
        constant: standardLeadingInset
      ),
      label.trailingAnchor.constraint(
        lessThanOrEqualTo: container.trailingAnchor,
        constant: -8
      ),
      label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      container.heightAnchor.constraint(equalToConstant: rowHeight),
    ])

    return container
  }

  @objc private func didSelectTool(_ sender: NSMenuItem) {
    guard let toolID = sender.representedObject as? String,
      let tool = registry.tools.first(where: { $0.id == toolID })
    else {
      return
    }
    presenter.present(tool)
  }

  @objc private func checkForUpdates() {
    updater?.checkForUpdates()
  }

  @objc private func showAbout() {
    NSApp.orderFrontStandardAboutPanel(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  @objc private func quitApp() {
    NSApp.terminate(nil)
  }
}
