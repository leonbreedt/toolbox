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
  let icon = "key.viewfinder"
  let presentationStyle = ToolPresentationStyle.window(
    size: CGSize(width: 640, height: 700),
    resizable: true
  )

  func makeView(context: ToolContext) -> AnyView {
    AnyView(JWTDecoderToolView(context: context))
  }
}
