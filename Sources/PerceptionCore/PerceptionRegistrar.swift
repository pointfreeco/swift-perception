import Foundation
import IssueReporting

/// Provides storage for tracking and access to data changes.
///
/// You don't need to create an instance of `PerceptionRegistrar` when using
/// the ``Perception/Perceptible()`` macro to indicate observability of a type.
@available(iOS, deprecated: 17, message: "Use 'ObservationRegistrar' instead.")
@available(macOS, deprecated: 14, message: "Use 'ObservationRegistrar' instead.")
@available(watchOS, deprecated: 10, message: "Use 'ObservationRegistrar' instead.")
@available(tvOS, deprecated: 17, message: "Use 'ObservationRegistrar' instead.")
public struct PerceptionRegistrar: Sendable {
  private let _rawValue: any Sendable
  #if DEBUG
    private let isPerceptionCheckingEnabled: Bool
    fileprivate let perceptionChecks = _ManagedCriticalState<[Location: Bool]>([:])
  #endif

  /// Creates an instance of the observation registrar.
  ///
  /// You don't need to create an instance of
  /// ``PerceptionRegistrar`` when using the
  /// ``Perception/Perceptible()`` macro to indicate observably
  /// of a type.
  public init(isPerceptionCheckingEnabled: Bool = PerceptionCore.isPerceptionCheckingEnabled) {
    if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta {
      #if canImport(Observation)
        self._rawValue = ObservationRegistrar()
      #else
        self._rawValue = _PerceptionRegistrar()
      #endif
    } else {
      self._rawValue = _PerceptionRegistrar()
    }
    #if DEBUG
      self.isPerceptionCheckingEnabled = isPerceptionCheckingEnabled
    #endif
  }

  #if canImport(Observation)
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    private var registrar: ObservationRegistrar {
      self._rawValue as! ObservationRegistrar
    }
  #endif

  private var perceptionRegistrar: _PerceptionRegistrar {
    self._rawValue as! _PerceptionRegistrar
  }
}

#if canImport(Observation)
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension PerceptionRegistrar {
    public func access<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      line: UInt = #line,
      column: UInt = #column
    ) {
      self.registrar.access(subject, keyPath: keyPath)
    }

    public func withMutation<Subject: Observable, Member, T>(
      of subject: Subject, keyPath: KeyPath<Subject, Member>, _ mutation: () throws -> T
    ) rethrows -> T {
      try self.registrar.withMutation(of: subject, keyPath: keyPath, mutation)
    }

    public func willSet<Subject: Observable, Member>(
      _ subject: Subject, keyPath: KeyPath<Subject, Member>
    ) {
      self.registrar.willSet(subject, keyPath: keyPath)
    }

    public func didSet<Subject: Observable, Member>(
      _ subject: Subject, keyPath: KeyPath<Subject, Member>
    ) {
      self.registrar.didSet(subject, keyPath: keyPath)
    }
  }
#endif

extension PerceptionRegistrar {
  @_disfavoredOverload
  public func access<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    #if DEBUG && canImport(SwiftUI)
      self.perceptionCheck(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    #endif
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta {
        func `open`<T: Observable>(_ subject: T) {
          self.registrar.access(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<T, Member>.self)
          )
        }
        if let subject = subject as? any Observable {
          return open(subject)
        }
      }
    #endif
    self.perceptionRegistrar.access(subject, keyPath: keyPath)
  }

  @_disfavoredOverload
  public func withMutation<Subject: Perceptible, Member, T>(
    of subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    _ mutation: () throws -> T
  ) rethrows -> T {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta,
        let subject = subject as? any Observable
      {
        func `open`<S: Observable>(_ subject: S) throws -> T {
          return try self.registrar.withMutation(
            of: subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self),
            mutation
          )
        }
        return try open(subject)
      }
    #endif
    return try self.perceptionRegistrar.withMutation(of: subject, keyPath: keyPath, mutation)
  }

  @_disfavoredOverload
  public func willSet<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>
  ) {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta,
        let subject = subject as? any Observable
      {
        func `open`<S: Observable>(_ subject: S) {
          return self.registrar.willSet(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self)
          )
        }
        return open(subject)
      }
    #endif
    return self.perceptionRegistrar.willSet(subject, keyPath: keyPath)
  }

  @_disfavoredOverload
  public func didSet<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>
  ) {
    #if canImport(Observation)
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta,
        let subject = subject as? any Observable
      {
        func `open`<S: Observable>(_ subject: S) {
          return self.registrar.didSet(
            subject,
            keyPath: unsafeDowncast(keyPath, to: KeyPath<S, Member>.self)
          )
        }
        return open(subject)
      }
    #endif
    return self.perceptionRegistrar.didSet(subject, keyPath: keyPath)
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

#if DEBUG && canImport(SwiftUI)
  extension PerceptionRegistrar {
    fileprivate func perceptionCheck(
      fileID: StaticString,
      filePath: StaticString,
      line: UInt,
      column: UInt
    ) {
      if self.isPerceptionCheckingEnabled,
        PerceptionCore.isPerceptionCheckingEnabled,
        !_PerceptionLocals.isInPerceptionTracking,
        !_PerceptionLocals.skipPerceptionChecking,
        self.isInSwiftUIBody(file: filePath, line: line)
      {
        reportIssue(
          """
          Perceptible state was accessed but is not being tracked. Track changes to state by \
          wrapping your view in a 'WithPerceptionTracking' view. This must also be done for any \
          escaping, trailing closures, such as 'GeometryReader', `LazyVStack` (and all lazy \
          views), navigation APIs ('sheet', 'popover', 'fullScreenCover', etc.), and others.
          """
        )
      }
    }

    fileprivate func isInSwiftUIBody(file: StaticString, line: UInt) -> Bool {
      self.perceptionChecks.withCriticalRegion { perceptionChecks in
        if let result = perceptionChecks[Location(file: file, line: line)] {
          return result
        }
        for callStackSymbol in Thread.callStackSymbols {
          let mangledSymbol = callStackSymbol.utf8
            .drop(while: { $0 != .init(ascii: "$") })
            .prefix(while: { $0 != .init(ascii: " ") })
          guard let demangled = String(Substring(mangledSymbol)).demangled
          else {
            continue
          }
          if demangled.isGeometryTrailingClosure {
            return !(demangled.isSuspendingClosure || demangled.isActionClosure)
          }
          guard
            mangledSymbol.isMangledViewBodyGetter,
            !demangled.isSuspendingClosure,
            !demangled.isActionClosure
          else {
            continue
          }
          return true
        }
        perceptionChecks[Location(file: file, line: line)] = false
        return false
      }
    }
  }

  extension String {
    var isGeometryTrailingClosure: Bool {
      self.contains("(SwiftUI.GeometryProxy) -> ")
    }

    fileprivate var isSuspendingClosure: Bool {
      let fragment = self.utf8.drop(while: { $0 != .init(ascii: ")") }).dropFirst()
      return fragment.starts(
        with: " suspend resume partial function for closure".utf8
      )
        || fragment.starts(
          with: " suspend resume partial function for implicit closure".utf8
        )
        || fragment.starts(
          with: " await resume partial function for partial apply forwarder for closure".utf8
        )
        || fragment.starts(
          with: " await resume partial function for partial apply forwarder for implicit closure"
            .utf8
        )
        || fragment.starts(
          with: " await resume partial function for implicit closure".utf8
        )
    }
    fileprivate var isActionClosure: Bool {
      var view = self[...].utf8
      view = view.drop(while: { $0 != .init(ascii: "#") })
      view = view.dropFirst()
      view = view.drop(while: { $0 >= .init(ascii: "0") && $0 <= .init(ascii: "9") })
      view = view.drop(while: { $0 != .init(ascii: "-") })
      return view.starts(with: "-> () in ".utf8)
    }
    fileprivate var demangled: String? {
      return self.utf8CString.withUnsafeBufferPointer { mangledNameUTF8CStr in
        let demangledNamePtr = swift_demangle(
          mangledName: mangledNameUTF8CStr.baseAddress,
          mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
          outputBuffer: nil,
          outputBufferSize: nil,
          flags: 0
        )
        if let demangledNamePtr = demangledNamePtr {
          let demangledName = String(cString: demangledNamePtr)
          free(demangledNamePtr)
          return demangledName
        }
        return nil
      }
    }
  }

  @_silgen_name("swift_demangle")
  private func swift_demangle(
    mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<CChar>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
  ) -> UnsafeMutablePointer<CChar>?
#endif

#if DEBUG
  public func _withoutPerceptionChecking<T>(
    _ apply: () -> T
  ) -> T {
    return _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
      apply()
    }
  }
#else
  @_transparent
  @inline(__always)
  public func _withoutPerceptionChecking<T>(
    _ apply: () -> T
  ) -> T {
    apply()
  }
#endif

#if DEBUG
  extension Substring.UTF8View {
    fileprivate var isMangledViewBodyGetter: Bool {
      self._contains("V4bodyQrvg".utf8)
    }
    fileprivate func _contains(_ other: String.UTF8View) -> Bool {
      guard let first = other.first
      else { return false }
      let otherCount = other.count
      var input = self
      while let index = input.firstIndex(where: { first == $0 }) {
        input = input[index...]
        if input.count >= otherCount,
          zip(input, other).allSatisfy(==)
        {
          return true
        }
        input.removeFirst()
      }
      return false
    }
  }

  private struct Location: Hashable {
    let file: String
    let line: UInt
    init(file: StaticString, line: UInt) {
      self.file = file.description
      self.line = line
    }
  }
#endif
