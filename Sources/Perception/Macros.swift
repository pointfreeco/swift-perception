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


#if $Macros && hasAttribute(attached)

/// Defines and implements conformance of the Perceptible protocol.
///
/// > Important: This is a back-port of Swift's `@Observable` macro.
///
/// This macro adds perception support to a custom type and conforms the type
/// to the ``Perception/Perceptible`` protocol. For example, the following code
/// applies the `Perceptible` macro to the type `Car` making it perceptible:
///
///     @Perceptible 
///     class Car {
///        var name: String = ""
///        var needsRepairs: Bool = false
///        
///        init(name: String, needsRepairs: Bool = false) {
///            self.name = name
///            self.needsRepairs = needsRepairs
///        }
///     }
@available(iOS, deprecated: 26, renamed: "Observable")
@available(macOS, deprecated: 26, renamed: "Observable")
@available(watchOS, deprecated: 26, renamed: "Observable")
@available(tvOS, deprecated: 26, renamed: "Observable")
@attached(member, names: named(_$perceptionRegistrar), named(access), named(withMutation), named(shouldNotifyObservers))
@attached(memberAttribute)
@attached(extension, conformances: Perceptible, Observable)
public macro Perceptible() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptibleMacro")

/// Synthesizes a property for accessors.
///
/// > Important: This is a back-port of Swift's `@ObservationTracked` macro.
///
/// The ``Perception`` module uses this macro. Its use outside of the
/// framework isn't necessary.
@available(iOS, deprecated: 26, renamed: "ObservationTracked")
@available(macOS, deprecated: 26, renamed: "ObservationTracked")
@available(watchOS, deprecated: 26, renamed: "ObservationTracked")
@available(tvOS, deprecated: 26, renamed: "ObservationTracked")
@attached(accessor, names: named(init), named(get), named(set), named(_modify))
@attached(peer, names: prefixed(_))
public macro PerceptionTracked() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptionTrackedMacro")

/// Disables perception tracking of a property.
///
/// > Important: This is a back-port of Swift's `@ObservationIgnored` macro.
///
/// By default, an object can perceive any property of a perceptible type that
/// is accessible to the perceiving object. To prevent perception of an
/// accessible property, attach the `PerceptionIgnored` macro to the property.
@available(iOS, deprecated: 26, renamed: "ObservationIgnored")
@available(macOS, deprecated: 26, renamed: "ObservationIgnored")
@available(watchOS, deprecated: 26, renamed: "ObservationIgnored")
@available(tvOS, deprecated: 26, renamed: "ObservationIgnored")
@attached(accessor, names: named(willSet))
public macro PerceptionIgnored() =
  #externalMacro(module: "PerceptionMacros", type: "PerceptionIgnoredMacro")

#endif
