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

struct _ThreadLocal {
  #if os(WASI)
    // NB: This can simply be 'nonisolated(unsafe)' when we drop support for Swift 5.9
    static var value: UnsafeMutableRawPointer? {
      get { _value.value }
      set { _value.value = newValue }
    }
    private let _value = UncheckedSendable<UnsafeMutableRawPointer?>(nil)
  #else
    static var value: UnsafeMutableRawPointer? {
      get { Thread.current.threadDictionary[Key()] as! UnsafeMutableRawPointer? }
      set { Thread.current.threadDictionary[Key()] = newValue }
    }
    private struct Key: Hashable {}
  #endif
}
