//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import AppKit

final class ToolWindow: NSWindow {
  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    if event.type == .keyDown {
      if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "w" {
        close()
        return true
      }

      if event.keyCode == 53 {
        close()
        return true
      }
    }

    return super.performKeyEquivalent(with: event)
  }
}
