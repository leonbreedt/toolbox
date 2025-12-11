//
//  Toolbox
//
//  Copyright (C) 2025-2026 Leon Breedt
//  All Rights Reserved
//

import Foundation

enum TokenError: Error {
  case invalidJWTFormat
  case invalidBase64(String)
  case invalidJSON(String)
}

extension TokenError: CustomStringConvertible {
  var description: String {
    switch self {
    case .invalidJWTFormat:
      "An encoded JWT must contain three '.' separated Base-64 encoded parts."
    case .invalidBase64(_):
      "A Base-64 string could not be decoded."
    case .invalidJSON(_):
      "JSON payload could not be parsed."
    }
  }
}

/// Represents an editable token, that recomputes dependent values when
/// fragments of the token are edited.
@Observable
final class EditableToken {
  var rawToken: String {
    didSet {
      extractAndDecodeParts(fromRawToken: rawToken)
    }
  }

  var headerBase64: String? {
    didSet {
      rebuildRawTokenFromParts()
    }
  }
  var payloadBase64: String? {
    didSet {
      rebuildRawTokenFromParts()
    }
  }
  var signatureBase64: String? {
    didSet {
      rebuildRawTokenFromParts()
    }
  }

  var headerJson: String? {
    didSet {
      headerBase64 = headerJson.map { base64UrlEncode($0) }
    }
  }

  var payloadJson: String? {
    didSet {
      payloadBase64 = payloadJson.map { base64UrlEncode($0) }
    }
  }
  private(set) var errorMessage: String?

  private var skipRebuildRawToken: Bool

  init(rawToken: String) {
    self.rawToken = rawToken
    self.skipRebuildRawToken = false

    extractAndDecodeParts(fromRawToken: rawToken)
  }

  private func extractAndDecodeParts(fromRawToken rawToken: String) {
    skipRebuildRawToken = true
    defer { skipRebuildRawToken = false }

    let trimmedToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedToken.isEmpty else {
      clearParts()
      errorMessage = nil
      return
    }

    do {
      try extractParts(fromRawToken: trimmedToken)
      decodeParts()

      errorMessage = nil
    } catch {
      errorMessage = "\(error.localizedDescription)"
    }
  }

  private func extractParts(fromRawToken rawToken: String) throws {
    let parts = rawToken.split(separator: ".").map(String.init)
    guard parts.count == 3 else {
      clearParts()
      throw TokenError.invalidJWTFormat
    }

    headerBase64 = parts[0]
    payloadBase64 = parts[1]
    signatureBase64 = parts[2]
  }

  private func clearParts() {
    skipRebuildRawToken = true
    defer { skipRebuildRawToken = false }

    headerJson = nil
    headerBase64 = nil
    payloadJson = nil
    payloadBase64 = nil
    signatureBase64 = nil
  }

  private func decodeParts() {
    let headerJsonData = headerBase64.flatMap { base64UrlDecode($0) }
    let payloadJsonData = payloadBase64.flatMap { base64UrlDecode($0) }
    let headerJsonString = headerJsonData.flatMap { stringFromAnyEncoding($0) }
    let payloadJsonString = payloadJsonData.flatMap {
      stringFromAnyEncoding($0)
    }

    headerJson =
      headerJsonString.flatMap { try? parseJsonString($0) }.flatMap {
        prettyPrintJson($0)
      } ?? headerJsonString
    payloadJson =
      payloadJsonString.flatMap { try? parseJsonString($0) }.flatMap {
        prettyPrintJson($0)
      } ?? payloadJsonString
  }

  private func rebuildRawTokenFromParts() {
    if skipRebuildRawToken {
      return
    }

    rawToken =
      "\(headerBase64 ?? "").\(payloadBase64 ?? "").\(signatureBase64 ?? "")"
  }
}

// From https://github.com/auth0/JWTDecode.swift/blob/master/JWTDecode/JWTDecode.swift
func base64UrlDecode(_ value: String) -> Data? {
  var base64 =
    value
    .replacingOccurrences(of: "-", with: "+")
    .replacingOccurrences(of: "_", with: "/")
  let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
  let requiredLength = 4 * ceil(length / 4.0)
  let paddingLength = requiredLength - length
  if paddingLength > 0 {
    let padding = "".padding(
      toLength: Int(paddingLength),
      withPad: "=",
      startingAt: 0
    )
    base64 += padding
  }
  return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

func base64UrlEncode(_ value: String) -> String {
  guard let data = value.data(using: .utf8) else { return "" }
  let base64 = data.base64EncodedString()
  return base64
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
}

private func parseJsonString(_ jsonString: String) throws -> [String: Any] {
  guard
    let jsonData = jsonString.data(using: .utf8),
    let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
    let jsonObject = json as? [String: Any]
  else {
    throw TokenError.invalidJSON(jsonString)
  }

  return jsonObject
}

private func prettyPrintJson(_ object: Any) -> String? {
  guard JSONSerialization.isValidJSONObject(object),
    let data = try? JSONSerialization.data(
      withJSONObject: object,
      options: [.prettyPrinted, .sortedKeys]
    )
  else {
    return nil
  }
  return String(data: data, encoding: .utf8)
}

private func stringFromAnyEncoding(_ data: Data) -> String? {
  let encodings: [String.Encoding] = [
    .utf8,
    .utf16, .utf16LittleEndian, .utf16BigEndian,
    .utf32, .utf32LittleEndian, .utf32BigEndian,
    .ascii,
    .isoLatin1,
    .windowsCP1252,
  ]
  for encoding in encodings {
    if let s = String(data: data, encoding: encoding) {
      return s
    }
  }
  return nil
}
