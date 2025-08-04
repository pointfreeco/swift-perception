import IssueReporting

#if canImport(SwiftUI)
  import SwiftUI
#endif

/// Provides storage for tracking and access to data changes.
///
/// You don't need to create an instance of `PerceptionRegistrar` when using
/// the ``Perception/Perceptible()`` macro to indicate perceptibility of a type.
@available(iOS, deprecated: 26, renamed: "ObservationRegistrar")
@available(macOS, deprecated: 26, renamed: "ObservationRegistrar")
@available(watchOS, deprecated: 26, renamed: "ObservationRegistrar")
@available(tvOS, deprecated: 26, renamed: "ObservationRegistrar")
public struct PerceptionRegistrar: Sendable {
  private let rawValue: any Sendable
  #if DEBUG
    public let _isPerceptionCheckingEnabled: Bool
  #endif
  #if DEBUG && canImport(SwiftUI)
    fileprivate let perceptionChecks = _ManagedCriticalState<[Int: Bool]>([:])
  #endif

  @usableFromInline var perceptionRegistrar: _PerceptionRegistrar {
    rawValue as! _PerceptionRegistrar
  }

  /// Creates an instance of the perception registrar.
  ///
  /// You don't need to create an instance of
  /// ``Perception/PerceptionRegistrar`` when using the
  /// ``Perception/Perceptible()`` macro to indicate perceptibility
  /// of a type.
  public init(isPerceptionCheckingEnabled: Bool = true) {
    #if DEBUG
      _isPerceptionCheckingEnabled = isPerceptionCheckingEnabled
    #endif
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta {
        rawValue = ObservationRegistrar()
        return
      }
    #endif
    rawValue = _PerceptionRegistrar()
  }

  /// Registers access to a specific property for perception.
  ///
  /// - Parameters:
  ///   - subject: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  @_disfavoredOverload
  #if DEBUG && canImport(SwiftUI)
    @_transparent
  #endif
  public func access<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>
  ) {
    #if DEBUG && canImport(SwiftUI)
      check()
    #endif
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
        !isObservationBeta,
        let subject = subject as? any Observable
      {
        func open<S: Observable>(_ subject: S) {
          observationRegistrar.access(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self)
          )
        }
        return open(subject)
      }
    #endif
    perceptionRegistrar.access(subject, keyPath: keyPath)
  }

  /// A property perception called before setting the value of the subject.
  ///
  /// - Parameters:
  ///     - subject: An instance of a perceptible type.
  ///     - keyPath: The key path of a perceived property.
  @_disfavoredOverload
  public func willSet<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>
  ) {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
        !isObservationBeta,
        let subject = subject as? any Observable
      {
        func open<S: Observable>(_ subject: S) {
          observationRegistrar.willSet(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self)
          )
        }
        return open(subject)
      }
    #endif
    perceptionRegistrar.willSet(subject, keyPath: keyPath)
  }

  /// A property perception called after setting the value of the subject.
  ///
  /// - Parameters:
  ///   - subject: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  @_disfavoredOverload
  public func didSet<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>
  ) {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
        !isObservationBeta,
        let subject = subject as? any Observable
      {
        func open<S: Observable>(_ subject: S) {
          observationRegistrar.didSet(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self)
          )
        }
        return open(subject)
      }
    #endif
    perceptionRegistrar.didSet(subject, keyPath: keyPath)
  }

  /// Identifies mutations to the transactions registered for perceivers.
  ///
  /// This method calls ``willSet(_:keyPath:)`` before the mutation. Then it
  /// calls ``didSet(_:keyPath:)`` after the mutation.
  /// - Parameters:
  ///   - of: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  @_disfavoredOverload
  public func withMutation<Subject: Perceptible, Member, T>(
    of subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    _ mutation: () throws -> T
  ) rethrows -> T {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
        !isObservationBeta,
        let subject = subject as? any Observable
      {
        func open<S: Observable>(_ subject: S) throws -> T {
          try observationRegistrar.withMutation(
            of: subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self),
            mutation
          )
        }
        return try open(subject)
      }
    #endif
    return try perceptionRegistrar.withMutation(of: subject, keyPath: keyPath, mutation)
  }
}

extension PerceptionRegistrar: Codable {
  public init(from decoder: any Decoder) throws {
    self.init()
  }

  public func encode(to encoder: any Encoder) {
    // Don't encode a registrar's transient state.
  }
}

extension PerceptionRegistrar: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    // A registrar should be ignored for the purposes of determining its
    // parent type's equality.
    return true
  }

  public func hash(into hasher: inout Hasher) {
    // Don't include a registrar's transient state in its parent type's
    // hash value.
  }
}

#if canImport(Observation)
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension PerceptionRegistrar {
    @usableFromInline var observationRegistrar: ObservationRegistrar {
      rawValue as! ObservationRegistrar
    }

    /// Registers access to a specific property for observation.
    ///
    /// - Parameters:
    ///   - subject: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    public func access<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
    ) {
      observationRegistrar.access(subject, keyPath: keyPath)
    }

    /// A property observation called before setting the value of the subject.
    ///
    /// - Parameters:
    ///     - subject: An instance of an observable type.
    ///     - keyPath: The key path of an observed property.
    public func willSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
    ) {
      observationRegistrar.willSet(subject, keyPath: keyPath)
    }

    /// A property observation called after setting the value of the subject.
    ///
    /// - Parameters:
    ///   - subject: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    public func didSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
    ) {
      observationRegistrar.didSet(subject, keyPath: keyPath)
    }

    /// Identifies mutations to the transactions registered for observers.
    ///
    /// This method calls ``willSet(_:keyPath:)`` before the mutation. Then it
    /// calls ``didSet(_:keyPath:)`` after the mutation.
    /// - Parameters:
    ///   - of: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    public func withMutation<Subject: Observable, Member, T>(
      of subject: Subject,
      keyPath: KeyPath<Subject, Member>,
      _ mutation: () throws -> T
    ) rethrows -> T {
      try observationRegistrar.withMutation(of: subject, keyPath: keyPath, mutation)
    }
  }
#endif

#if DEBUG && canImport(SwiftUI)
  extension PerceptionRegistrar {
    @_transparent
    @usableFromInline
    func check() {
      if _isPerceptionCheckingEnabled,
        PerceptionCore.isPerceptionCheckingEnabled,
        !_PerceptionLocals.isInPerceptionTracking,
        !_PerceptionLocals.skipPerceptionChecking,
        isSwiftUI()
      {
        reportIssue(
          """
          Perceptible state was accessed from a view but is not being tracked.

          Use this warning's stack trace to locate the view in question and wrap it with a \
          'WithPerceptionTracking' view. For example:

            var body: some View
              WithPerceptionTracking {
                // ...
              }
            }

          This must also be done for any subviews with escaping trailing closures, such as \
          'GeometryReader':

            GeometryReader { proxy in
              WithPerceptionTracking {
                // ...
              }
            }

          If a view is using a binding derived from perceptible '@State', use \
          '@Perception.Bindable', instead. For example:

            @State var model = Model()
            var body: some View
              WithPerceptionTracking {
                @Perception.Bindable var model = model
                Stepper("\\(count)", value: $model.count)
              }
            }

          """
        )
      }
    }

    @usableFromInline
    func isSwiftUI() -> Bool {
      // NB: Unrelated stacks could potentially collide, but we want to keep debug builds lean, so
      //     we can afford the rare false positive/negative.
      let location = Thread.callStackReturnAddresses.hashValue
      return perceptionChecks.withCriticalRegion { perceptionChecks in
        if let result = perceptionChecks[location] {
          return result
        }
        let result = Thread.callStackSymbols.reversed().contains {
          $0.utf8.dropFirst(4).starts(with: "AttributeGraph ".utf8)
        }
        perceptionChecks[location] = result
        return result
      }
    }
  }
#endif
