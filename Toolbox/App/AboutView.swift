//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import AppKit
import SwiftUI

struct AboutView: View {
  private let appName: String
  private let versionString: String
  private let copyrightText: String?
  private let appIcon: NSImage

  init() {
    let info = Bundle.main.infoDictionary ?? [:]
    let name =
      (info["CFBundleDisplayName"] as? String)?.nilIfEmpty
      ?? (info["CFBundleName"] as? String)?.nilIfEmpty
      ?? "Toolbox"
    self.appName = name

    let version = (info["CFBundleShortVersionString"] as? String)?.nilIfEmpty ?? "1.0"
    let build = (info["CFBundleVersion"] as? String)?.nilIfEmpty ?? "1"
    self.versionString = "Version \(version) (\(build))"
    self.copyrightText = (info["NSHumanReadableCopyright"] as? String)?.nilIfEmpty ?? ""

    self.appIcon = NSApp.applicationIconImage
  }

  var body: some View {
    VStack(spacing: 14) {
      Image(nsImage: appIcon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 64, height: 64)
        .cornerRadius(12)

      Text(appName)
        .font(.system(size: 18, weight: .semibold))

      Text(versionString)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)

      Divider()
        .padding(.vertical, 4)

      if let copyright = copyrightText {
        Text(copyright)
          .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 12)
      }

      Spacer(minLength: 0)
    }
    .padding(20)
    .frame(minWidth: 360, minHeight: 220)
  }
}

extension String {
  fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
