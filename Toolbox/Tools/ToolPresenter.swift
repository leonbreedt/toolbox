//
//  Toolbox
//
//  Copyright (C) 2025-2026 Sector 42 Limited
//  All Rights Reserved
//

import AppKit
import Foundation
import SwiftUI

@MainActor
final class ToolPresenter: NSObject, NSWindowDelegate {
  private var windowsByToolID: [String: NSWindow] = [:]
  private var toolIDByWindow: [ObjectIdentifier: String] = [:]

  func present(_ tool: any Tool) {
    if let existing = windowsByToolID[tool.id] {
      bringWindowToFront(existing)
      return
    }

    let context = ToolContext(toolID: tool.id)
    let baseView = tool.makeView(context: context)

    switch tool.presentationStyle {
    case .window(let size, let resizable):
      let sizedView = AnyView(baseView.frame(minWidth: size.width, minHeight: size.height))
      let window = makeWindow(for: tool, view: sizedView, size: size, resizable: resizable)

      register(window: window, forToolID: tool.id)
      bringWindowToFront(window)

    case .popover(let size):
      let sizedView = AnyView(baseView.frame(minWidth: size.width, minHeight: size.height))
      let window = makeWindow(for: tool, view: sizedView, size: size, resizable: false)

      register(window: window, forToolID: tool.id)
      bringWindowToFront(window)
    }
  }

  func dismiss(toolID: String) {
    guard let window = windowsByToolID[toolID] else { return }

    window.delegate = nil
    window.close()

    unregister(window: window)
  }

  func dismissAll() {
    for (_, window) in windowsByToolID {
      window.delegate = nil
      window.close()
    }

    windowsByToolID.removeAll()
    toolIDByWindow.removeAll()
  }

  private func makeWindow(for tool: any Tool, view: AnyView, size: CGSize, resizable: Bool)
    -> NSWindow
  {
    let baseMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
    let styleMask: NSWindow.StyleMask = resizable ? baseMask.union(.resizable) : baseMask

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
      styleMask: styleMask,
      backing: .buffered,
      defer: false
    )
    window.title = tool.name
    window.titleVisibility = .visible
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.isReleasedWhenClosed = false
    window.delegate = self
    window.level = .normal

    let hosting = NSHostingController(rootView: view)
    window.contentViewController = hosting
    window.setContentSize(NSSize(width: size.width, height: size.height))

    if resizable {
      window.contentMinSize = NSSize(width: max(320, size.width), height: max(200, size.height))
    } else {
      window.contentMinSize = NSSize(width: size.width, height: size.height)
    }

    window.center()
    return window
  }

  private func register(window: NSWindow, forToolID toolID: String) {
    windowsByToolID[toolID] = window
    toolIDByWindow[ObjectIdentifier(window)] = toolID
  }

  private func unregister(window: NSWindow) {
    let key = ObjectIdentifier(window)
    if let toolID = toolIDByWindow[key] {
      toolIDByWindow.removeValue(forKey: key)
      windowsByToolID.removeValue(forKey: toolID)
    }
  }

  private func bringWindowToFront(_ window: NSWindow) {
    NSApp.activate(ignoringOtherApps: true)

    if window.isMiniaturized {
      window.deminiaturize(nil)
    }

    window.level = .normal
    window.makeKeyAndOrderFront(nil)
    window.orderFrontRegardless()

    // Second activate call helps in some edge cases (Spaces/full-screen).
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }

    unregister(window: window)
  }
}
