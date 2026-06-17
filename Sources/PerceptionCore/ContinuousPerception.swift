//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _Concurrency

/// > Important: This is a back-port of Swift's `withContinuousObservation` function.
@available(iOS, deprecated: 27, renamed: "withContinuousObservation")
@available(macOS, deprecated: 27, renamed: "withContinuousObservation")
@available(watchOS, deprecated: 27, renamed: "withContinuousObservation")
@available(tvOS, deprecated: 27, renamed: "withContinuousObservation")
public func withContinuousPerception(
  options: PerceptionTracking.Options = .willSet,
  @_inheritActorContext apply:
    @isolated(any) @Sendable @escaping (borrowing PerceptionTracking.Event) -> Void
) -> PerceptionTracking.Token {
  let perception = ContinuousPerception(options: options, apply)
  return perception.token
}

extension PerceptionTracking {
  public struct Token: ~Copyable {
    fileprivate var state: _ManagedCriticalState<ContinuousPerception.State>

    public consuming func cancel() {
      ContinuousPerception.State.cancel(state)
    }

    deinit {
      ContinuousPerception.State.cancel(state)
    }
  }
}

struct ContinuousPerception: ~Copyable {
  // Tracks whether the didSet of the tracking has occurred (kind of).
  // Whether it has come to the point of suspension after the isolation. "Next suspension on
  // the isolation after the willSet"
  struct State: Sendable {
    // When `true`, this means to keep running because there is more to do (wait for the
    // next suspension point).
    var continuation: UnsafeContinuation<Bool, Never>?
    var isInitial: Bool = true
    // Tracks whether a change occurred before the cancellation, but has not called the
    // synchronize closure yet. This allows that `synchronize` to be called for that value still.
    var dirty = false
    var cancelled = false
    var event: (PerceptionTracking.Event.Kind, PerceptionTracking?)?
  }

  fileprivate let state = _ManagedCriticalState(State())

  // Initialize with a closure where you access all properties you wish for changes to be tracked.
  // Inside the closure, you should use the properties and transform them to set on other objects.
  // This closure will be called continuously whenever any tracked property changes to a new
  // value.
  //
  // - Note: The closure will be called isolated to the same actor this type is initialized on.
  // - Parameters:
  //     - synchronize: A closure that will be called whenever any of the tracked properties
  //     change.
  //         - `context`: Information as to the current iteration to allow you to change your code.
  //         For instance, `isInitial` so you can choose to do something difference for the initial
  //         value rather than when it changes.
  init(
    options: PerceptionTracking.Options,
    @_inheritActorContext _ apply:
      @isolated(any) @Sendable @escaping (borrowing PerceptionTracking.Event) -> Void
  ) {
    ContinuousPerception.run(state, options: options, apply: apply)
  }

  var token: PerceptionTracking.Token {
    PerceptionTracking.Token(state: state)
  }
}

extension ContinuousPerception.State {
  fileprivate static func emitEvent(
    _ state: _ManagedCriticalState<ContinuousPerception.State>,
    _ event: borrowing PerceptionTracking.Event
  ) {
    let kind = event.kind
    let tracking = event.tracking
    let (continuation, terminal) = state.withCriticalRegion {
      state -> (UnsafeContinuation<Bool, Never>?, Bool) in
      let continuation = state.continuation
      state.isInitial = false
      state.dirty = true
      state.continuation = nil
      state.event = (kind, tracking)
      return (continuation, state.cancelled)
    }
    if let continuation {
      continuation.resume(returning: !terminal)
    }
  }

  // If the return value is true, you should continue to listen for the next change. If false,
  // you should end immediately and not listen to the next change.
  fileprivate static func populate(
    _ state: _ManagedCriticalState<ContinuousPerception.State>,
    continuation: UnsafeContinuation<Bool, Never>
  ) -> Bool {
    // Continuation stays suspend until you get the new willSet trigger and the value is whether
    // you should keep observing.
    let (continuation, dirty) = state.withCriticalRegion {
      state -> (UnsafeContinuation<Bool, Never>?, Bool) in
      assert(state.continuation == nil)
      let dirty = state.dirty
      state.dirty = false
      if state.cancelled {
        return (continuation, dirty)
      } else {
        state.continuation = continuation
        return (nil, dirty)
      }
    }
    if let continuation {
      // This is an early resume saying this is cancelled
      continuation.resume(returning: false)
      // If something already hit the willSet (dirty == true), then continue with one more
      // value change.
      return dirty
    } else {
      return true
    }
  }

  static func cancel(_ state: _ManagedCriticalState<ContinuousPerception.State>) {
    state.withCriticalRegion { state in
      let continuation = state.continuation
      state.cancelled = true
      state.continuation = nil
      return continuation
    }?.resume(returning: false)
  }

  // This will sit on an iteration of the loop until a `willSet`
  // occurs for one of the tracked properties. Then, it will perform
  // another iteration of the loop.
  //
  // Taking in the isolation ensures that we don't hop to another actor.
  fileprivate static func trackingLoop(
    isolation: isolated (any Actor)?,
    _ state: _ManagedCriticalState<ContinuousPerception.State>,
    options: PerceptionTracking.Options,
    apply:
      @isolated(any) @escaping @Sendable (
        borrowing PerceptionTracking.Event
      ) -> Void
  ) async {
    while await track(state, options: options, apply: apply) {}
  }

  fileprivate static func track(
    _ state: _ManagedCriticalState<ContinuousPerception.State>,
    options: PerceptionTracking.Options,
    apply:
      @isolated(any) @escaping @Sendable (
        borrowing PerceptionTracking.Event
      ) -> Void
  ) async -> Bool {
    return await withIsolatedTaskCancellationHandler(
      operation: {
        return await withUnsafeContinuation(isolation: apply.isolation) {
          continuation in
          guard
            ContinuousPerception.State.populate(state, continuation: continuation)
          else {
            return
          }
          withPerceptionTracking(options: options) {
            // This is safe since we have already been isolated to the tracking isolation.
            let fn = apply as @Sendable (borrowing PerceptionTracking.Event) -> Void
            // This ends up also being how the `didSet` is called because this will occur
            // on the next iteration of the while loop from `trackingLoop` after the
            // onChange.
            let kindAndTracking = state.withCriticalRegion { state in
              defer { state.event = nil }
              return state.event
            }
            if let kindAndTracking {
              fn(.init(kindAndTracking.1, continuousState: state, kind: kindAndTracking.0))
            } else {
              fn(.init(nil, continuousState: state, kind: .initial))
            }
          } onChange: { event in
            // This will trigger this whole `track` method to be called again, causing the
            // `apply` closure to run.
            ContinuousPerception.State.emitEvent(state, event)
          }
        }
      },
      onCancel: {
        ContinuousPerception.State.cancel(state)
      },
      isolation: apply.isolation
    )
  }
}

// MARK: - Runner
extension ContinuousPerception {
  fileprivate static func run(
    _ state: _ManagedCriticalState<State>,
    options: PerceptionTracking.Options,
    apply: @isolated(any) @Sendable @escaping (borrowing PerceptionTracking.Event) -> Void
  ) {
    Task.detached {
      await State.trackingLoop(
        isolation: apply.isolation,
        state,
        options: options,
        apply: apply
      )
    }
  }
}
