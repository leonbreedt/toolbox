//
//  Toolbox
//
//  Copyright (C) 2025-2026 Sector 42 Limited
//  All Rights Reserved
//

import SwiftUI

struct WelcomeView: View {
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "wrench.and.screwdriver")
        .font(.system(size: 60))
        .foregroundStyle(.tint)

      Text("Welcome to Toolbox")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Your menu bar utility collection")
        .font(.title3)
        .foregroundStyle(.secondary)

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "menubar.rectangle")
            .frame(width: 24)
          Text("Access tools from the menu bar")
        }

        HStack {
          Image(systemName: "square.grid.2x2")
            .frame(width: 24)
          Text("Organized by category")
        }

        HStack {
          Image(systemName: "arrow.clockwise")
            .frame(width: 24)
          Text("Tools remember their state")
        }
      }
      .padding()
      .background(Color.secondary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))

      Button("Dismiss") {
        onDismiss()
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
    .padding(40)
    .frame(width: 500, height: 450)
  }
}
