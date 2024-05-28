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
    static var value: UnsafeMutableRawPointer?
  #else
    static var value: UnsafeMutableRawPointer? {
      get { Thread.current.threadDictionary[Key()] as! UnsafeMutableRawPointer? }
      set { Thread.current.threadDictionary[Key()] = newValue }
    }
    private struct Key: Hashable {}
  #endif
}
