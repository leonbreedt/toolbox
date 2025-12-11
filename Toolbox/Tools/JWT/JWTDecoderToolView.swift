//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import SwiftUI

private let rawTokenContextKey: String = "rawToken"

struct JWTDecoderToolView: View {
  let context: ToolContext

  @State private var editableToken: EditableToken

  @State private var appActiveObserver: NSObjectProtocol?
  @State private var windowKeyObserver: NSObjectProtocol?

  init(context: ToolContext) {
    self.context = context

    let savedRawToken: String? = context.load(forKey: rawTokenContextKey)
    self._editableToken = State(
      initialValue: EditableToken(rawToken: savedRawToken ?? "")
    )
  }

  private var headerColor: Color { Color(hex: "#2B5F55") }
  private var payloadColor: Color { .black }
  private var signatureColor: Color { Color(hex: "#2F3D9A") }
  private let tokenPaneMinHeight: CGFloat = 240
  private let headerPaneMinHeight: CGFloat = 160
  private let payloadPaneMinHeight: CGFloat = 200
  private let panePadding: CGFloat = 12

  var body: some View {
    VStack(spacing: 8) {
      if let message = editableToken.errorMessage, !message.isEmpty {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.yellow)
          Text(message)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .font(.callout)
        .padding(.horizontal, 4)
      }

      VSplitView {
        Pane(paddingTop: panePadding, paddingBottom: panePadding) {
          GroupBox("Token") {
            RawTokenPartsEditor(
              text: $editableToken.rawToken,
              font: NSFont.monospacedSystemFont(
                ofSize: 13,
                weight: .regular
              ),
              headerColor: NSColor(headerColor),
              payloadColor: NSColor(payloadColor),
              signatureColor: NSColor(signatureColor),
              placeholder: "Paste token here..."
            )
            .frame(minHeight: 200, maxHeight: .infinity)
            .onChange(of: editableToken.rawToken) { _, newValue in
              context.save(newValue, forKey: rawTokenContextKey)
            }
          }
          .layoutPriority(1)
        }
        .frame(minHeight: tokenPaneMinHeight)
        .layoutPriority(1)

        Pane(paddingTop: panePadding, paddingBottom: panePadding) {
          GroupBox("Header") {
            TextEditor(
              text: Binding(
                get: { editableToken.headerJson ?? "" },
                set: { editableToken.headerJson = $0.isEmpty ? nil : $0 }
              )
            )
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(headerColor)
            .frame(minHeight: 100, idealHeight: 140)
            .textSelection(.enabled)
            .padding(6)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
          }
        }
        .frame(minHeight: headerPaneMinHeight)
        .layoutPriority(1)

        Pane(paddingTop: panePadding, paddingBottom: panePadding) {
          GroupBox("Payload") {
            TextEditor(
              text: Binding(
                get: { editableToken.payloadJson ?? "" },
                set: { editableToken.payloadJson = $0.isEmpty ? nil : $0 }
              )
            )
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(payloadColor)
            .frame(minHeight: 140, idealHeight: 300, maxHeight: .infinity)
            .textSelection(.enabled)
            .padding(6)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
          }
        }
        .frame(minHeight: payloadPaneMinHeight)
        .layoutPriority(1)
      }
      .frame(maxHeight: .infinity)
    }
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          editableToken.rawToken = ""
          context.save(editableToken.rawToken, forKey: rawTokenContextKey)
        } label: {
          Label("Clear", systemImage: "trash")
        }
      }
    }
    .onAppear {
      autoImportFromClipboardIfJWT()

      appActiveObserver = NotificationCenter.default.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { _ in
        autoImportFromClipboardIfJWT()
      }

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

  @ViewBuilder
  private func Pane<Content: View>(
    paddingTop: CGFloat = 12,
    paddingBottom: CGFloat = 12,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: 0) {
      content()
    }
    .padding(.top, paddingTop)
    .padding(.bottom, paddingBottom)
  }

  private func autoImportFromClipboardIfJWT() {
    guard
      let candidate = NSPasteboard.general.string(forType: .string)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !candidate.isEmpty,
      candidate != editableToken.rawToken,
      looksLikeJWT(candidate)
    else {
      return
    }

    editableToken.rawToken = candidate
    context.save(editableToken.rawToken, forKey: rawTokenContextKey)
  }

  private func looksLikeJWT(_ token: String) -> Bool {
    let parts = token.split(separator: ".")
    guard parts.count == 3 else { return false }
    return parts.allSatisfy { part in
      (try? base64UrlDecode(String(part))) != nil
    }
  }
}

extension Color {
  fileprivate init(hex: String) {
    let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(
        of: "#",
        with: ""
      )
    var int: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255.0
    let g = Double((int >> 8) & 0xFF) / 255.0
    let b = Double(int & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}

#Preview {
  JWTDecoderToolView(context: ToolContext(toolID: "jwtdecoder"))
}
