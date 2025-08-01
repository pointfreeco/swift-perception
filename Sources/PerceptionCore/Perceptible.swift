//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//


/// A type that emits notifications to perceivers when underlying data changes.
///
/// > Important: This is a back-port of Swift's `Observable` protocol.
///
/// Conforming to this protocol signals to other APIs that the type supports
/// perception. However, applying the `Perceptible` protocol by itself to a
/// type doesn't add perception functionality to the type. Instead, always use
/// the ``Perception/Perceptible()`` macro when adding perception
/// support to a type.
@available(iOS, deprecated: 26, renamed: "Observable")
@available(macOS, deprecated: 26, renamed: "Observable")
@available(watchOS, deprecated: 26, renamed: "Observable")
@available(tvOS, deprecated: 26, renamed: "Observable")
public protocol Perceptible { }
