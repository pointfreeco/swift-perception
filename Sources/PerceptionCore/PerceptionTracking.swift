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

@_spi(SwiftUI)
public struct PerceptionTracking: Sendable {
  enum Id {
    case willSet(Int)
    case didSet(Int)
    case full(Int, Int)
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
    internal var entries = [ObjectIdentifier : Entry]()

    internal init() { }
    
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

  @_spi(SwiftUI)
  public static func _installTracking(
    _ tracking: PerceptionTracking,
    willSet: (@Sendable (PerceptionTracking) -> Void)? = nil,
    didSet: (@Sendable (PerceptionTracking) -> Void)? = nil
  ) {
    let values = tracking.list.entries.mapValues { 
      switch (willSet, didSet) {
      case (.some(let willSetPerceiver), .some(let didSetPerceiver)):
        return Id.full($0.addWillSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          willSetPerceiver(tracking)
        }, $0.addDidSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          didSetPerceiver(tracking)
        })
      case (.some(let willSetPerceiver), .none):
        return Id.willSet($0.addWillSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          willSetPerceiver(tracking)
        })
      case (.none, .some(let didSetPerceiver)):
        return Id.didSet($0.addDidSetPerceiver { keyPath in
          tracking.state.withCriticalRegion { $0.changed = keyPath }
          didSetPerceiver(tracking)
        })
      case (.none, .none):
        fatalError()
      }  
    }
    
    tracking.install(values)
  }

  @_spi(SwiftUI)
  public static func _installTracking(
    _ list: _AccessList,
    onChange: @escaping @Sendable () -> Void
  ) {
    let tracking = PerceptionTracking(list)
    _installTracking(tracking, willSet: { _ in
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

  internal func install(_ values:  [ObjectIdentifier : PerceptionTracking.Id]) {
    state.withCriticalRegion {
      if !$0.cancelled {
        $0.values = values
      }
    }
  }

  public func cancel() {
    let values = state.withCriticalRegion {
      $0.cancelled = true
      let values = $0.values
      $0.values = [:]
      return values
    }
    for (id, perceptionId) in values {
        switch perceptionId {
        case .willSet(let token):
          list.entries[id]?.removePerceiver(token)
        case .didSet(let token):
          list.entries[id]?.removePerceiver(token)
        case .full(let willSetToken, let didSetToken):
          list.entries[id]?.removePerceiver(willSetToken)
          list.entries[id]?.removePerceiver(didSetToken)
        }
      }
  }

  public var changed: AnyKeyPath? {
      state.withCriticalRegion { $0.changed }
  }
}

fileprivate func generateAccessList<T>(_ apply: () -> T) -> (T, PerceptionTracking._AccessList?) {
  var accessList: PerceptionTracking._AccessList?
  let result = withUnsafeMutablePointer(to: &accessList) { ptr in
    let previous = _ThreadLocal.value
    _ThreadLocal.value = UnsafeMutableRawPointer(ptr)
    defer {
      if let scoped = ptr.pointee, let previous {
        if var prevList = previous.assumingMemoryBound(to: PerceptionTracking._AccessList?.self).pointee {
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

@_spi(SwiftUI)
public func withPerceptionTracking<T>(
  _ apply: () -> T,
  willSet: @escaping @Sendable (PerceptionTracking) -> Void,
  didSet: @escaping @Sendable (PerceptionTracking) -> Void
) -> T {
  let (result, accessList) = generateAccessList(apply)
  PerceptionTracking._installTracking(PerceptionTracking(accessList), willSet: willSet, didSet: didSet)
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
