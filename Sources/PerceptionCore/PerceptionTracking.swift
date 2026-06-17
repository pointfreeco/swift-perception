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

#if canImport(Observation)
  import Observation
#endif

public struct PerceptionTracking: Sendable {
  struct Id {
    var willSet: Int?
    var didSet: Int?
    var `deinit`: Int?
  }

  struct Entry: @unchecked Sendable {
    let context: _PerceptionRegistrar.Context

    var properties: Set<AnyKeyPath>

    init(_ context: _PerceptionRegistrar.Context, properties: Set<AnyKeyPath> = []) {
      self.context = context
      self.properties = properties
    }

    func addWillSetPerceiver(_ changed: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      return context.registerTracking(for: properties, willSet: changed)
    }

    func addDidSetPerceiver(_ changed: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      return context.registerTracking(for: properties, didSet: changed)
    }

    func addDeinitPerceiver(_ changed: @Sendable @escaping () -> Void) -> Int {
      return context.registerTracking(deinit: changed)
    }

    func removePerceiver(_ token: Int) {
      context.cancel(token)
    }

    mutating func insert(_ keyPath: AnyKeyPath) {
      properties.insert(keyPath)
    }

    func union(_ entry: Entry) -> Entry {
      Entry(context, properties: properties.union(entry.properties))
    }
  }

  @_spi(SwiftUI)
  public struct _AccessList: Sendable {
    internal var entries = [ObjectIdentifier: Entry]()

    internal init() {}

    internal mutating func addAccess<Subject: Perceptible>(
      keyPath: PartialKeyPath<Subject>,
      context: _PerceptionRegistrar.Context
    ) {
      entries[context.id, default: Entry(context)].insert(keyPath)
    }

    internal mutating func merge(_ other: _AccessList) {
      entries.merge(other.entries) { existing, entry in
        existing.union(entry)
      }
    }
  }

  static func _installTracking(
    options: PerceptionTracking.Options,
    _ tracking: PerceptionTracking,
    willSet: (@Sendable (PerceptionTracking) -> Void)? = nil,
    didSet: (@Sendable (PerceptionTracking) -> Void)? = nil,
    `deinit`: (@Sendable () -> Void)? = nil
  ) {
    let values = tracking.list.entries.mapValues {
      var id = Id()
      if let willSet {
        id.willSet = $0.addWillSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          willSet(tracking)
        }
      }
      if let didSet {
        id.didSet = $0.addDidSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          didSet(tracking)
        }
      }
      if let `deinit` {
        id.deinit = $0.addDeinitPerceiver(`deinit`)
      }
      return id
    }

    tracking.install(values)
  }

  @_spi(SwiftUI)
  public static func _installTracking(
    _ tracking: PerceptionTracking,
    willSet: (@Sendable (PerceptionTracking) -> Void)? = nil,
    didSet: (@Sendable (PerceptionTracking) -> Void)? = nil
  ) {
    let values = tracking.list.entries.mapValues {
      var id = Id()
      if let willSet {
        id.willSet = $0.addWillSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          willSet(tracking)
        }
      }
      if let didSet {
        id.didSet = $0.addDidSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          didSet(tracking)
        }
      }
      return id
    }

    tracking.install(values)
  }

  @_spi(SwiftUI)
  public static func _installTracking(
    _ list: _AccessList,
    onChange: @escaping @Sendable () -> Void
  ) {
    let tracking = PerceptionTracking(list)
    _installTracking(
      tracking,
      willSet: { _ in
        onChange()
        tracking.cancel()
      })
  }

  struct State: @unchecked Sendable {
    var values = [ObjectIdentifier: PerceptionTracking.Id]()
    var cancelled = false
    var changed: AnyKeyPath?
  }

  private let state = _ManagedCriticalState(State())
  private let list: _AccessList

  @_spi(SwiftUI)
  public init(_ list: _AccessList?) {
    self.list = list ?? _AccessList()
  }

  internal func install(_ values: [ObjectIdentifier: PerceptionTracking.Id]) {
    state.withCriticalRegion {
      if !$0.cancelled {
        $0.values = values
      }
    }
  }

  @_spi(SwiftUI)
  public func cancel() {
    let values = state.withCriticalRegion {
      $0.cancelled = true
      let values = $0.values
      $0.values = [:]
      return values
    }
    for (id, perceptionId) in values {
      if let token = perceptionId.willSet {
        list.entries[id]?.removePerceiver(token)
      }
      if let token = perceptionId.didSet {
        list.entries[id]?.removePerceiver(token)
      }
      if let token = perceptionId.deinit {
        list.entries[id]?.removePerceiver(token)
      }
    }
  }

  @_spi(SwiftUI)
  public var changed: AnyKeyPath? {
    state.withCriticalRegion { $0.changed }
  }

  /// > Important: This is a back-port of Swift's `ObservationTracking.Options`.
  public struct Options {
    struct RawValue: OptionSet {
      var rawValue: Int

      init(rawValue: Int) {
        self.rawValue = rawValue
      }

      static var willSet: RawValue { .init(rawValue: 1 << 0) }
      static var didSet: RawValue { .init(rawValue: 1 << 1) }
      static var `deinit`: RawValue { .init(rawValue: 1 << 2) }
      static var continuous: RawValue { .init(rawValue: 1 << 3) }
      static var updating: RawValue { .init(rawValue: 1 << 4) }
    }
    var rawValue: RawValue

    init(rawValue: RawValue) {
      self.rawValue = rawValue
    }

    public init() {
      rawValue = RawValue()
    }

    public static var willSet: Options { Options(rawValue: .willSet) }

    public static var didSet: Options { Options(rawValue: .didSet) }

    public static var `deinit`: Options { Options(rawValue: .deinit) }
  }

  /// > Important: This is a back-port of Swift's `ObservationTracking.Event`.
  public struct Event: ~Copyable {
    public struct Kind: Equatable, Sendable {
      enum RawValue {
        case initial
        case willSet
        case didSet
        case `deinit`
      }

      var rawValue: RawValue

      public static var initial: Kind { Kind(rawValue: .initial) }

      public static var willSet: Kind { Kind(rawValue: .willSet) }

      public static var didSet: Kind { Kind(rawValue: .didSet) }

      public static var `deinit`: Kind { Kind(rawValue: .deinit) }
    }

    public private(set) var kind: Kind

    var tracking: PerceptionTracking?
    var continuousState: _ManagedCriticalState<ContinuousPerception.State>?

    init(_ tracking: PerceptionTracking?, kind: Kind) {
      self.kind = kind
      self.tracking = tracking
    }

    init(
      _ tracking: PerceptionTracking?,
      continuousState: _ManagedCriticalState<ContinuousPerception.State>,
      kind: Kind
    ) {
      self.kind = kind
      self.tracking = tracking
      self.continuousState = continuousState
    }

    public func matches(_ keyPath: PartialKeyPath<some Perceptible>) -> Bool {
      return tracking?.changed == keyPath
    }

    public func cancel() {
      tracking?.cancel()
      if let continuousState {
        ContinuousPerception.State.cancel(continuousState)
      }
    }
  }
}

extension PerceptionTracking.Options: SetAlgebra {
  public init(arrayLiteral elements: PerceptionTracking.Options...) {
    var rawValue = RawValue()
    for element in elements {
      rawValue.rawValue |= element.rawValue.rawValue
    }
    self.init(rawValue: rawValue)
  }

  public func union(_ other: Self) -> Self {
    Self(rawValue: rawValue.union(other.rawValue))
  }

  public func intersection(_ other: Self) -> Self {
    Self(rawValue: rawValue.intersection(other.rawValue))
  }

  public func symmetricDifference(_ other: Self) -> Self {
    Self(rawValue: rawValue.symmetricDifference(other.rawValue))
  }

  public mutating func formUnion(_ other: Self) {
    rawValue.formUnion(other.rawValue)
  }

  public mutating func formIntersection(_ other: Self) {
    rawValue.formIntersection(other.rawValue)
  }

  public mutating func formSymmetricDifference(_ other: Self) {
    rawValue.formSymmetricDifference(other.rawValue)
  }

  public func contains(_ member: Self) -> Bool {
    rawValue.contains(member.rawValue)
  }

  @discardableResult
  public mutating func insert(
    _ newMember: Self
  ) -> (inserted: Bool, memberAfterInsert: Self) {
    let (inserted, memberAfterInsert) = rawValue.insert(newMember.rawValue)
    return (inserted, Self(rawValue: memberAfterInsert))
  }

  @discardableResult
  public mutating func remove(_ member: Self) -> Self? {
    rawValue.remove(member.rawValue).map { Self(rawValue: $0) }
  }

  @discardableResult
  public mutating func update(with newMember: Self) -> Self? {
    rawValue.update(with: newMember.rawValue).map { Self(rawValue: $0) }
  }
}

extension PerceptionTracking.Options: Sendable {}

private func generateAccessList<T>(_ apply: () -> T) -> (T, PerceptionTracking._AccessList?) {
  var accessList: PerceptionTracking._AccessList?
  let result = withUnsafeMutablePointer(to: &accessList) { ptr in
    let previous = _ThreadLocal.value
    _ThreadLocal.value = UnsafeMutableRawPointer(ptr)
    defer {
      if let scoped = ptr.pointee, let previous {
        if var prevList = previous.assumingMemoryBound(to: PerceptionTracking._AccessList?.self)
          .pointee
        {
          prevList.merge(scoped)
          previous.assumingMemoryBound(to: PerceptionTracking._AccessList?.self).pointee = prevList
        } else {
          previous.assumingMemoryBound(to: PerceptionTracking._AccessList?.self).pointee = scoped
        }
      }
      _ThreadLocal.value = previous
    }
    return apply()
  }
  return (result, accessList)
}

/// Tracks access to properties.
///
/// > Important: This is a back-port of Swift's `withObservationTracking` function.
///
/// This method tracks access to any property within the `apply` closure, and
/// informs the caller of value changes made to participating properties by way
/// of the `onChange` closure. For example, the following code tracks changes
/// to the name of cars, but it doesn't track changes to any other property of
/// `Car`:
///
///     func render() {
///         withPerceptionTracking {
///             for car in cars {
///                 print(car.name)
///             }
///         } onChange: {
///             print("Schedule renderer.")
///         }
///     }
///
/// - Parameters:
///     - apply: A closure that contains properties to track.
///     - onChange: The closure invoked when the value of a property changes.
///
/// - Returns: The value that the `apply` closure returns if it has a return
/// value; otherwise, there is no return value.
@available(iOS, deprecated: 17, renamed: "withObservationTracking")
@available(macOS, deprecated: 14, renamed: "withObservationTracking")
@available(watchOS, deprecated: 10, renamed: "withObservationTracking")
@available(tvOS, deprecated: 17, renamed: "withObservationTracking")
public func withPerceptionTracking<T>(
  _ apply: () -> T,
  onChange: @autoclosure () -> @Sendable () -> Void
) -> T {
  #if DEBUG && canImport(SwiftUI)
    let apply = { _PerceptionLocals.$isInPerceptionTracking.withValue(true, operation: apply) }
  #endif
  #if canImport(Observation)
    if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta {
      return withObservationTracking(apply, onChange: onChange())
    }
  #endif
  let (result, accessList) = generateAccessList(apply)
  if let accessList {
    PerceptionTracking._installTracking(accessList, onChange: onChange())
  }
  return result
}

/// Tracks access to properties, delivering a structured event on each change.
///
/// > Important: This is a back-port of Swift's `withObservationTracking(options:_:onChange:)`
/// > function.
///
/// - Parameters:
///     - options: The events to observe.
///     - apply: A closure that contains properties to track.
///     - onChange: The closure invoked when an observed event occurs.
///
/// - Returns: The value that the `apply` closure returns if it has a return
/// value; otherwise, there is no return value.
@available(iOS, deprecated: 27, renamed: "withObservationTracking")
@available(macOS, deprecated: 27, renamed: "withObservationTracking")
@available(watchOS, deprecated: 27, renamed: "withObservationTracking")
@available(tvOS, deprecated: 27, renamed: "withObservationTracking")
public func withPerceptionTracking<T>(
  options: PerceptionTracking.Options,
  _ apply: () -> T,
  onChange: @escaping @Sendable (borrowing PerceptionTracking.Event) -> Void
) -> T {
  #if DEBUG && canImport(SwiftUI)
    let apply = { _PerceptionLocals.$isInPerceptionTracking.withValue(true, operation: apply) }
  #endif
  let (result, accessList) = generateAccessList(apply)
  let willSet: (@Sendable (PerceptionTracking) -> Void)?
  if options.contains(.willSet) {
    willSet = { tracking in
      onChange(PerceptionTracking.Event(tracking, kind: .willSet))
      if !options.rawValue.contains(.continuous) && !options.contains(.didSet) {
        tracking.cancel()
      }
    }
  } else {
    willSet = nil
  }
  let didSet: (@Sendable (PerceptionTracking) -> Void)?
  if options.contains(.didSet) {
    didSet = { tracking in
      onChange(PerceptionTracking.Event(tracking, kind: .didSet))
      if !options.rawValue.contains(.continuous) {
        tracking.cancel()
      }
    }
  } else {
    didSet = nil
  }
  let `deinit`: (@Sendable () -> Void)?
  if options.contains(.deinit) {
    `deinit` = {
      onChange(PerceptionTracking.Event(nil, kind: .deinit))
    }
  } else {
    `deinit` = nil
  }
  let tracking = PerceptionTracking(accessList)
  PerceptionTracking._installTracking(
    options: options, tracking, willSet: willSet, didSet: didSet, deinit: `deinit`
  )
  return result
}

@_spi(SwiftUI)
public func withPerceptionTracking<T>(
  _ apply: () -> T,
  willSet: @escaping @Sendable (PerceptionTracking) -> Void,
  didSet: @escaping @Sendable (PerceptionTracking) -> Void
) -> T {
  let (result, accessList) = generateAccessList(apply)
  PerceptionTracking._installTracking(
    PerceptionTracking(accessList), willSet: willSet, didSet: didSet)
  return result
}

@_spi(SwiftUI)
public func withPerceptionTracking<T>(
  _ apply: () -> T,
  willSet: @escaping @Sendable (PerceptionTracking) -> Void
) -> T {
  let (result, accessList) = generateAccessList(apply)
  PerceptionTracking._installTracking(PerceptionTracking(accessList), willSet: willSet, didSet: nil)
  return result
}

@_spi(SwiftUI)
public func withPerceptionTracking<T>(
  _ apply: () -> T,
  didSet: @escaping @Sendable (PerceptionTracking) -> Void
) -> T {
  let (result, accessList) = generateAccessList(apply)
  PerceptionTracking._installTracking(PerceptionTracking(accessList), willSet: nil, didSet: didSet)
  return result
}
