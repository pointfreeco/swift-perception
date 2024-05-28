//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation

@_silgen_name("_swift_observation_tls_get")
func _tlsGet() -> UnsafeMutableRawPointer?

@_silgen_name("_swift_observation_tls_set")
func _tlsSet(_ value: UnsafeMutableRawPointer?)

struct _ThreadLocal {
  static var value: UnsafeMutableRawPointer? {
    get {
      _tlsGet()
    }
    set {
      _tlsSet(newValue)
    }
  }
}
