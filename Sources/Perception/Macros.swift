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

@available(iOS, deprecated: 17, renamed: "Observable")
@available(macOS, deprecated: 14, renamed: "Observable")
@available(tvOS, deprecated: 17, renamed: "Observable")
@available(watchOS, deprecated: 10, renamed: "Observable")
@attached(
  member, names: named(_$id), named(_$perceptionRegistrar), named(access), named(withMutation))
@attached(memberAttribute)
#if canImport(Observation)
  @attached(extension, conformances: Observable, Perceptible)
#else
  @attached(extension, conformances: Perceptible)
#endif
public macro Perceptible() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptibleMacro")

@available(iOS, deprecated: 17, renamed: "ObservationTracked")
@available(macOS, deprecated: 14, renamed: "ObservationTracked")
@available(tvOS, deprecated: 17, renamed: "ObservationTracked")
@available(watchOS, deprecated: 10, renamed: "ObservationTracked")
@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(_))
public macro PerceptionTracked() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptionTrackedMacro")

@available(iOS, deprecated: 17, renamed: "ObservationIgnored")
@available(macOS, deprecated: 14, renamed: "ObservationIgnored")
@available(tvOS, deprecated: 17, renamed: "ObservationIgnored")
@available(watchOS, deprecated: 10, renamed: "ObservationIgnored")
@attached(accessor, names: named(willSet))
public macro PerceptionIgnored() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptionIgnoredMacro")
