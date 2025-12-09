//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import SwiftUI

@MainActor
struct JWTDecoderTool: @MainActor Tool {
  let id = "jwtdecoder"
  let name = "JWT Decoder"
  let category = ToolCategory.development
  let icon = "lock.open"
  let presentationStyle = ToolPresentationStyle.window(
    size: CGSize(width: 600, height: 620), resizable: true)

  func makeView(context: ToolContext) -> AnyView {
    AnyView(JWTDecoderView(context: context))
  }
}

struct JWTDecoderView: View {
  let context: ToolContext

  @State private var input: String
  @State private var headerPretty: String = ""
  @State private var payloadPretty: String = ""
  @State private var signatureBase64URL: String = ""
  @State private var signatureBytes: Int = 0
  @State private var errorMessage: String?

  // Editable JSON text for header and payload
  @State private var headerJSONText: String = ""
  @State private var payloadJSONText: String = ""

  // Guard flags to avoid feedback loops when updating programmatically
  @State private var isProgrammaticInputUpdate = false
  @State private var isProgrammaticHeaderUpdate = false
  @State private var isProgrammaticPayloadUpdate = false

  // Keep observer tokens to remove them on disappear
  @State private var appActiveObserver: NSObjectProtocol?
  @State private var windowKeyObserver: NSObjectProtocol?

  init(context: ToolContext) {
    self.context = context
    let saved: String? = context.load(forKey: "input")
    self._input = State(initialValue: saved ?? "")
  }

  // Custom colors
  private var headerColor: Color { Color(hex: "#2B5F55") }
  private var payloadColor: Color { .black }
  private var signatureColor: Color { Color(hex: "#2F3D9A") }

  var body: some View {
    VStack(spacing: 12) {
      // Controls
      HStack {
        Button {
          if let paste = NSPasteboard.general.string(forType: .string) {
            input = paste.trimmingCharacters(in: .whitespacesAndNewlines)
            context.save(input, forKey: "input")
            decode()
          }
        } label: {
          Label("Paste", systemImage: "doc.on.clipboard")
        }
        .buttonStyle(.bordered)

        Button {
          input = ""
          context.save(input, forKey: "input")
          clearOutput()
        } label: {
          Label("Clear", systemImage: "trash")
        }
        .buttonStyle(.bordered)

        Spacer()

        Button {
          decode()
        } label: {
          Label("Decode", systemImage: "arrow.down.doc")
        }
        .buttonStyle(.borderedProminent)
      }

      // Input (colorized while editing)
      GroupBox("Encoded JWT") {
        ColorizedTextEditor(
          text: $input,
          font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
          headerColor: NSColor(headerColor),
          payloadColor: NSColor(payloadColor),
          signatureColor: NSColor(signatureColor)
        )
        .frame(minHeight: 80)
        .onChange(of: input) { _, newValue in
          if !isProgrammaticInputUpdate {
            context.save(newValue, forKey: "input")
            decode()
          }
        }
      }

      if let message = errorMessage, !message.isEmpty {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.yellow)
          Text(message)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .font(.callout)
      }

      // Editable Output
      HStack(spacing: 12) {
        GroupBox("Header") {
          TextEditor(text: $headerJSONText)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(headerColor)
            .frame(minHeight: 120)
            .textSelection(.enabled)
            .padding(6)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: headerJSONText) { _, _ in
              if !isProgrammaticHeaderUpdate {
                rebuildTokenFromEditedParts()
              }
            }
        }

        GroupBox("Payload") {
          TextEditor(text: $payloadJSONText)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(payloadColor)
            .frame(minHeight: 120)
            .textSelection(.enabled)
            .padding(6)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: payloadJSONText) { _, _ in
              if !isProgrammaticPayloadUpdate {
                rebuildTokenFromEditedParts()
              }
            }
        }
      }

      GroupBox("Signature") {
        HStack(alignment: .firstTextBaseline) {
          Text(signatureBase64URL.isEmpty ? "—" : signatureBase64URL)
            .font(.system(.body, design: .monospaced))  // Match header/payload font
            .foregroundStyle(signatureColor)
            .textSelection(.enabled)
            .lineLimit(2)
            .truncationMode(.middle)
          Spacer()
          if signatureBytes > 0 {
            Text("\(signatureBytes) bytes")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Button {
            if !signatureBase64URL.isEmpty {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(signatureBase64URL, forType: .string)
            }
          } label: {
            Image(systemName: "doc.on.doc")
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .disabled(signatureBase64URL.isEmpty)
        }
      }
    }
    .padding(12)
    .onAppear {
      // Initial decode if we already have input
      if !input.isEmpty {
        decode()
      } else {
        autoImportFromClipboardIfJWT()
      }
      // Observe app activation (foreground)
      appActiveObserver = NotificationCenter.default.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { _ in
        autoImportFromClipboardIfJWT()
      }
      // Observe window focus (becoming key)
      windowKeyObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.didBecomeKeyNotification,
        object: nil,
        queue: .main
      ) { _ in
        autoImportFromClipboardIfJWT()
      }
    }
    .onDisappear {
      if let o = appActiveObserver {
        NotificationCenter.default.removeObserver(o)
        appActiveObserver = nil
      }
      if let o = windowKeyObserver {
        NotificationCenter.default.removeObserver(o)
        windowKeyObserver = nil
      }
    }
  }

  private func clearOutput() {
    headerPretty = ""
    payloadPretty = ""
    signatureBase64URL = ""
    signatureBytes = 0
    errorMessage = nil
    headerJSONText = ""
    payloadJSONText = ""
  }

  private func decode() {
    clearOutput()
    let token = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty else { return }

    let parts = token.split(separator: ".").map(String.init)
    guard parts.count == 3 else {
      errorMessage = "JWT should contain three parts separated by dots."
      return
    }

    let headerPart = parts[0]
    let payloadPart = parts[1]
    let signaturePart = parts[2]

    // Decode header
    do {
      let headerData = try decodeBase64URL(headerPart)
      let pretty =
        prettyPrintedJSON(from: headerData) ?? String(data: headerData, encoding: .utf8)
        ?? "(binary)"
      headerPretty = pretty
      if let jsonString = String(data: headerData, encoding: .utf8) {
        isProgrammaticHeaderUpdate = true
        headerJSONText = prettyPrintedJSONString(fromString: jsonString) ?? jsonString
        isProgrammaticHeaderUpdate = false
      }
    } catch {
      errorMessage = "Header decode error: \(error.localizedDescription)"
    }

    // Decode payload
    do {
      let payloadData = try decodeBase64URL(payloadPart)
      let pretty =
        prettyPrintedJSON(from: payloadData) ?? String(data: payloadData, encoding: .utf8)
        ?? "(binary)"
      payloadPretty = pretty
      if let jsonString = String(data: payloadData, encoding: .utf8) {
        isProgrammaticPayloadUpdate = true
        payloadJSONText = prettyPrintedJSONString(fromString: jsonString) ?? jsonString
        isProgrammaticPayloadUpdate = false
      }
    } catch {
      let msg = "Payload decode error: \(error.localizedDescription)"
      errorMessage = errorMessage == nil ? msg : "\(errorMessage!) • \(msg)"
    }

    // Signature (keep base64url as-is, but compute raw bytes)
    signatureBase64URL = signaturePart
    if let bytes = try? decodeBase64URL(signaturePart) {
      signatureBytes = bytes.count
    } else {
      signatureBytes = 0
    }
  }

  private func rebuildTokenFromEditedParts() {
    // Parse edited JSON. If either side is invalid JSON, do not update token.
    guard let headerData = jsonData(from: headerJSONText),
      let payloadData = jsonData(from: payloadJSONText)
    else {
      errorMessage = "Edited header or payload is not valid JSON."
      return
    }

    // Base64URL-encode both parts
    let headerB64 = base64URLEncode(headerData)
    let payloadB64 = base64URLEncode(payloadData)

    // Keep the existing signature (may be invalid cryptographically, but user requested to keep it)
    let rebuilt = [headerB64, payloadB64, signatureBase64URL].joined(separator: ".")

    // Update input programmatically to avoid recursion and trigger decode
    isProgrammaticInputUpdate = true
    input = rebuilt
    context.save(input, forKey: "input")
    isProgrammaticInputUpdate = false

    // Maintain signature info
    if let bytes = try? decodeBase64URL(signatureBase64URL) {
      signatureBytes = bytes.count
    } else {
      signatureBytes = 0
    }

    // Update pretty strings
    headerPretty =
      prettyPrintedJSONString(fromData: headerData) ?? String(data: headerData, encoding: .utf8)
      ?? ""
    payloadPretty =
      prettyPrintedJSONString(fromData: payloadData) ?? String(data: payloadData, encoding: .utf8)
      ?? ""

    // Clear transient error if JSON is valid
    errorMessage = nil
  }

  private func autoImportFromClipboardIfJWT() {
    guard
      let candidate = NSPasteboard.general.string(forType: .string)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !candidate.isEmpty,
      candidate != input,
      looksLikeJWT(candidate)
    else { return }
    input = candidate
    context.save(input, forKey: "input")
    decode()
  }

  // Quick structural validation that the string is a JWT:
  private func looksLikeJWT(_ token: String) -> Bool {
    let parts = token.split(separator: ".")
    guard parts.count == 3 else { return false }
    return parts.allSatisfy { part in
      (try? decodeBase64URL(String(part))) != nil
    }
  }

  private func decodeBase64URL(_ s: String) throws -> Data {
    var base = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    let rem = base.count % 4
    if rem == 2 {
      base.append("==")
    } else if rem == 3 {
      base.append("=")
    } else if rem == 1 {
      throw NSError(
        domain: "JWTDecoder", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Invalid base64url length"])
    }
    guard let data = Data(base64Encoded: base) else {
      throw NSError(
        domain: "JWTDecoder", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Invalid base64url data"])
    }
    return data
  }

  private func prettyPrintedJSON(from data: Data) -> String? {
    do {
      let obj = try JSONSerialization.jsonObject(with: data, options: [])
      let pretty = try JSONSerialization.data(
        withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
      return String(data: pretty, encoding: .utf8)
    } catch {
      return nil
    }
  }

  private func prettyPrintedJSONString(fromData data: Data) -> String? {
    prettyPrintedJSON(from: data)
  }

  private func prettyPrintedJSONString(fromString s: String) -> String? {
    guard let data = s.data(using: .utf8) else { return nil }
    return prettyPrintedJSON(from: data)
  }

  private func jsonData(from s: String) -> Data? {
    // Accept either minified or pretty JSON
    guard let data = s.data(using: .utf8) else { return nil }
    do {
      let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
      return try JSONSerialization.data(withJSONObject: obj, options: [])
    } catch {
      return nil
    }
  }

  private func base64URLEncode(_ data: Data) -> String {
    var s = data.base64EncodedString()
    s = s.replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return s
  }
}

// MARK: - Colorized NSView-backed editor

struct ColorizedTextEditor: NSViewRepresentable {
  @Binding var text: String
  var font: NSFont
  var headerColor: NSColor
  var payloadColor: NSColor
  var signatureColor: NSColor

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
      width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
    textView.textContainer?.widthTracksTextView = true

    scrollView.documentView = textView

    // Initial content
    textView.string = text
    context.coordinator.applyHighlight(in: textView)

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else { return }
    if textView.string != text {
      context.coordinator.isProgrammaticChange = true
      let selected = textView.selectedRange()
      textView.string = text
      textView.setSelectedRange(selected.clamped(to: textView.string))
      context.coordinator.isProgrammaticChange = false
    }
    context.coordinator.applyHighlight(in: textView)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    var parent: ColorizedTextEditor
    var isProgrammaticChange = false

    init(_ parent: ColorizedTextEditor) {
      self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
      guard !isProgrammaticChange,
        let textView = notification.object as? NSTextView
      else { return }
      parent.text = textView.string
      applyHighlight(in: textView)
    }

    func applyHighlight(in textView: NSTextView) {
      guard let storage = textView.textStorage else { return }
      let fullRange = NSRange(location: 0, length: storage.length)
      let baseAttrs: [NSAttributedString.Key: Any] = [
        .font: parent.font,
        .foregroundColor: NSColor.labelColor,
      ]

      // Reset base attributes
      storage.setAttributes(baseAttrs, range: fullRange)

      // Compute ranges for header.payload.signature, leaving dots default-colored
      let s = textView.string as NSString
      let string = s as String
      if string.isEmpty { return }

      let parts = string.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false).map(
        String.init)
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
            [.foregroundColor: color], range: NSRange(location: loc, length: len))
        }
        loc += len
        // Skip the dot between parts (keeps default color)
        if idx < parts.count - 1 {
          loc += 1
        }
      }
    }
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

// MARK: - Hex Color convenience

extension Color {
  fileprivate init(hex: String) {
    let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
      of: "#", with: "")
    var int: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255.0
    let g = Double((int >> 8) & 0xFF) / 255.0
    let b = Double(int & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}
