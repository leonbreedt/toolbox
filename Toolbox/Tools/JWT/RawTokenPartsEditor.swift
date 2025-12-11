//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import SwiftUI

/// Raw JWT token editor, colorizing the header, payload and signature parts.
struct RawTokenPartsEditor: NSViewRepresentable {
  @Binding var text: String
  
  let font: NSFont
  let headerColor: NSColor
  let payloadColor: NSColor
  let signatureColor: NSColor
  let placeholder: String?

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false

    let textView = NSTextView()
    textView.delegate = context.coordinator
    textView.isEditable = true
    textView.isSelectable = true
    textView.isRichText = false
    textView.allowsUndo = true
    textView.usesFindBar = true
    textView.font = font
    textView.textColor = NSColor.labelColor
    textView.drawsBackground = false
    textView.textContainerInset = NSSize(width: 4, height: 6)
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = true
    textView.autoresizingMask = [.width]
    textView.textContainer?.containerSize = NSSize(
      width: scrollView.contentSize.width,
      height: .greatestFiniteMagnitude
    )
    textView.textContainer?.widthTracksTextView = true

    scrollView.documentView = textView

    if let placeholder = placeholder {
      let label = NSTextField(labelWithString: placeholder)
      label.textColor = .placeholderTextColor
      label.font = font
      label.isBezeled = false
      label.drawsBackground = false
      label.lineBreakMode = .byTruncatingTail
      label.maximumNumberOfLines = 1
      label.alphaValue = 1.0
      label.translatesAutoresizingMaskIntoConstraints = false
      label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

      if let contentView = scrollView.contentView as NSView? {
        contentView.addSubview(label)

        let inset = textView.textContainerInset
        NSLayoutConstraint.activate([
          label.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: inset.width + 2
          ),
          label.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: inset.height
          ),
          label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -4)
        ])
      }

      context.coordinator.placeholderLabel = label
    }

    textView.string = text
    context.coordinator.applyHighlight(in: textView)
    context.coordinator.updatePlaceholderVisibility(for: textView)

    NotificationCenter.default.addObserver(
      context.coordinator,
      selector: #selector(Coordinator.windowDidChangeFirstResponder(_:)),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      context.coordinator,
      selector: #selector(Coordinator.windowDidChangeFirstResponder(_:)),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else {
      return
    }
    if textView.string != text {
      context.coordinator.isProgrammaticChange = true
      let selected = textView.selectedRange()
      textView.string = text
      textView.setSelectedRange(selected.clamped(to: textView.string))
      context.coordinator.isProgrammaticChange = false
    }
    context.coordinator.applyHighlight(in: textView)
    context.coordinator.updatePlaceholderVisibility(for: textView)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var parent: RawTokenPartsEditor
    var isProgrammaticChange = false
    weak var placeholderLabel: NSTextField?

    init(_ parent: RawTokenPartsEditor) {
      self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
      guard !isProgrammaticChange,
        let textView = notification.object as? NSTextView
      else { return }
      parent.text = textView.string
      applyHighlight(in: textView)
      updatePlaceholderVisibility(for: textView)
    }

    func applyHighlight(in textView: NSTextView) {
      guard let storage = textView.textStorage else { return }
      let fullRange = NSRange(location: 0, length: storage.length)
      let baseAttrs: [NSAttributedString.Key: Any] = [
        .font: parent.font,
        .foregroundColor: NSColor.labelColor,
      ]

      storage.setAttributes(baseAttrs, range: fullRange)

      let s = textView.string as NSString
      let string = s as String
      if string.isEmpty { return }

      let parts = string.split(
        separator: ".",
        maxSplits: 2,
        omittingEmptySubsequences: false
      ).map(
        String.init
      )
      var loc = 0

      for (idx, part) in parts.enumerated() {
        let len = part.count
        if len > 0 {
          let color: NSColor
          switch idx {
          case 0: color = parent.headerColor
          case 1: color = parent.payloadColor
          default: color = parent.signatureColor
          }
          storage.addAttributes(
            [.foregroundColor: color],
            range: NSRange(location: loc, length: len)
          )
        }
        loc += len

        // Skip the dot between parts (keeps default color)
        if idx < parts.count - 1 {
          loc += 1
        }
      }
    }

    func updatePlaceholderVisibility(for textView: NSTextView) {
      guard let label = placeholderLabel else { return }
      let isEmpty = textView.string.isEmpty
      let isFirstResponder = (textView.window?.firstResponder as? NSView) === textView
      // Show when empty and not focused (or show when empty regardless; tweak as desired)
      label.isHidden = !isEmpty
      // Optionally dim further when focused
      if isEmpty && isFirstResponder {
        label.alphaValue = 0.6
      } else {
        label.alphaValue = 1.0
      }
    }

    @objc func windowDidChangeFirstResponder(_ notification: Notification) {
      guard
        let window = notification.object as? NSWindow,
        let textView = window.contentView?.descendants().compactMap({ $0 as? NSTextView }).first
      else { return }
      updatePlaceholderVisibility(for: textView)
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }
}

private extension NSView {
  func descendants() -> [NSView] {
    var result: [NSView] = [self]
    for sub in subviews {
      result.append(contentsOf: sub.descendants())
    }
    return result
  }
}

extension NSRange {
  fileprivate func clamped(to string: String) -> NSRange {
    let maxLen = (string as NSString).length
    let newLocation = max(0, min(location, maxLen))
    let newLength = max(0, min(length, maxLen - newLocation))
    return NSRange(location: newLocation, length: newLength)
  }
}
