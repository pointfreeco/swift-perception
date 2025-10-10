import IssueReporting

#if canImport(SwiftUI)
  import SwiftUI
#endif

#if DEBUG && canImport(SwiftUI)
  import MachO
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

            var body: some View {
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
            var body: some View {
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

        let result = Thread.callStackReturnAddresses.contains { address in
          attributeGraphAddresses.contains(UInt(bitPattern: address.pointerValue))
        }

        perceptionChecks[location] = result
        return result
      }
    }
  }

  private let attributeGraphAddresses: RangeSet = {
    var addresses = RangeSet()
    let imageCount = _dyld_image_count()
    for i in 0..<imageCount {
      guard let imageName = _dyld_get_image_name(i) else { continue }
      if String(cString: imageName).hasSuffix("/AttributeGraph") {
        guard let ptr = _dyld_get_image_header(i) else { continue }
        let slide = _dyld_get_image_vmaddr_slide(i)

        #if arch(x86_64) || arch(arm64)
          typealias mach_header = mach_header_64
          typealias segment_command = segment_command_64
          let header = ptr.withMemoryRebound(to: mach_header_64.self, capacity: 1, \.pointee)
          let LC_SEGMENT = LC_SEGMENT_64
        #else
          let header = ptr.pointee
        #endif

        var commandPtr = UnsafeRawPointer(ptr).advanced(by: MemoryLayout<mach_header>.size)
        for _ in 0..<header.ncmds {
          let cmd = commandPtr.load(as: load_command.self)
          if cmd.cmd == LC_SEGMENT {
            let segment = commandPtr.load(as: segment_command.self)
            if segment.vmsize > 0 {
              let start = UInt(bitPattern: Int(segment.vmaddr) + slide)
              let end = UInt(bitPattern: Int(segment.vmaddr + segment.vmsize) + slide)
              addresses.insert(contentsOf: start..<end)
            }
          }
          commandPtr = commandPtr.advanced(by: Int(cmd.cmdsize))
        }
      }
    }
    return addresses
  }()

  //===--- RangeSet.swift ---------------------------------------*- swift -*-===//
  //
  // This source file is part of the Swift.org open source project
  //
  // Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
  // Licensed under Apache License v2.0 with Runtime Library Exception
  //
  // See https://swift.org/LICENSE.txt for license information
  // See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
  //
  //===----------------------------------------------------------------------===//

  struct RangeSet {
    @usableFromInline
    internal var _ranges: Ranges

    var ranges: Ranges {
      return _ranges
    }

    init() {
      _ranges = Ranges()
    }

    @usableFromInline
    internal init(_ranges: Ranges) {
      self._ranges = _ranges
    }

    var isEmpty: Bool {
      _ranges.isEmpty
    }

    func contains(_ value: UInt) -> Bool {
      _ranges._contains(value)
    }

    @inlinable
    mutating func insert(contentsOf range: Range<UInt>) {
      if range.isEmpty { return }
      _ranges._insert(contentsOf: range)
    }

    mutating func remove(contentsOf range: Range<UInt>) {
      if range.isEmpty { return }
      _ranges._remove(contentsOf: range)
    }
  }

  extension RangeSet: Equatable {
    static func == (left: Self, right: Self) -> Bool {
      left._ranges == right._ranges
    }
  }

  extension RangeSet {
    struct Ranges {
      internal var _storage: ContiguousArray<Range<UInt>>

      @usableFromInline
      internal init() {
        _storage = []
      }

      @usableFromInline
      internal init(_range: Range<UInt>) {
        _storage = [_range]
      }

      @usableFromInline
      internal init(_ranges: [Range<UInt>]) {
        _storage = ContiguousArray(_ranges)
      }

      @usableFromInline
      internal init(_unorderedRanges: [Range<UInt>]) {
        _storage = ContiguousArray(_unorderedRanges)
        _storage.sort {
          $0.lowerBound < $1.lowerBound
        }

        guard let firstNonEmpty = _storage.firstIndex(where: { $0.isEmpty == false }) else {
          _storage = []
          return
        }

        _storage.swapAt(0, firstNonEmpty)

        var lastValid = 0
        var current = firstNonEmpty + 1

        while current < _storage.count {
          defer { current += 1 }

          if _storage[current].isEmpty { continue }

          if _storage[lastValid].upperBound >= _storage[current].lowerBound {
            let newUpper = Swift.max(
              _storage[lastValid].upperBound,
              _storage[current].upperBound
            )
            _storage[lastValid] = Range(
              uncheckedBounds: (_storage[lastValid].lowerBound, newUpper)
            )
          } else {
            lastValid += 1
            _storage.swapAt(current, lastValid)
          }
        }

        _storage.removeSubrange((lastValid + 1)..<_storage.count)
      }
    }
  }

  extension RangeSet.Ranges {
    @usableFromInline
    internal func _contains(_ bound: UInt) -> Bool {
      let i = _storage._partitioningIndex { $0.upperBound > bound }
      return i == _storage.endIndex ? false : _storage[i].lowerBound <= bound
    }

    @usableFromInline
    internal func _indicesOfRange(
      _ range: Range<UInt>,
      in subranges: ContiguousArray<Range<UInt>>,
      includeAdjacent: Bool = true
    ) -> Range<Int> {
      guard subranges.count > 1 else {
        if subranges.isEmpty {
          return 0..<0
        } else {
          let subrange = subranges[0]
          if range.upperBound < subrange.lowerBound {
            return 0..<0
          } else if range.lowerBound > subrange.upperBound {
            return 1..<1
          } else {
            return 0..<1
          }
        }
      }

      let beginningIndex = subranges._partitioningIndex {
        if includeAdjacent {
          $0.upperBound >= range.lowerBound
        } else {
          $0.upperBound > range.lowerBound
        }
      }

      let endingIndex = subranges[beginningIndex...]._partitioningIndex {
        if includeAdjacent {
          $0.lowerBound > range.upperBound
        } else {
          $0.lowerBound >= range.upperBound
        }
      }

      return beginningIndex..<endingIndex
    }

    @usableFromInline
    @discardableResult
    internal mutating func _insert(contentsOf range: Range<UInt>) -> Bool {
      let indices = _indicesOfRange(range, in: _storage)
      if indices.isEmpty {
        _storage.insert(range, at: indices.lowerBound)
        return true
      } else {
        let lower = Swift.min(
          _storage[indices.lowerBound].lowerBound,
          range.lowerBound
        )
        let upper = Swift.max(
          _storage[indices.upperBound - 1].upperBound,
          range.upperBound
        )
        let newRange = lower..<upper
        if indices.count == 1 && newRange == _storage[indices.lowerBound] {
          return false
        }
        _storage.replaceSubrange(indices, with: CollectionOfOne(newRange))
        return true
      }
    }

    @usableFromInline
    internal mutating func _remove(contentsOf range: Range<UInt>) {
      let indices = _indicesOfRange(range, in: _storage, includeAdjacent: false)
      guard !indices.isEmpty else {
        return
      }

      let overlapsLowerBound =
        range.lowerBound > _storage[indices.lowerBound].lowerBound
      let overlapsUpperBound =
        range.upperBound < _storage[indices.upperBound - 1].upperBound

      switch (overlapsLowerBound, overlapsUpperBound) {
      case (false, false):
        _storage.removeSubrange(indices)
      case (false, true):
        let newRange =
          range.upperBound..<_storage[indices.upperBound - 1].upperBound
        _storage.replaceSubrange(indices, with: CollectionOfOne(newRange))
      case (true, false):
        let newRange =
          _storage[indices.lowerBound].lowerBound..<range.lowerBound
        _storage.replaceSubrange(indices, with: CollectionOfOne(newRange))
      case (true, true):
        _storage.replaceSubrange(
          indices,
          with: _Pair(
            _storage[indices.lowerBound].lowerBound..<range.lowerBound,
            range.upperBound..<_storage[indices.upperBound - 1].upperBound
          )
        )
      }
    }

    @usableFromInline
    internal func _union(_ other: Self) -> Self {
      if other.isEmpty {
        return self
      } else if self.isEmpty {
        return other
      }

      var a = self._storage
      var b = other._storage
      var aIndex = a.startIndex
      var bIndex = b.startIndex

      var result: [Range<UInt>] = []
      while aIndex < a.endIndex, bIndex < b.endIndex {
        if b[bIndex].lowerBound < a[aIndex].lowerBound {
          swap(&a, &b)
          swap(&aIndex, &bIndex)
        }

        var candidateRange = a[aIndex]
        aIndex += 1

        while bIndex < b.endIndex, candidateRange.upperBound >= b[bIndex].lowerBound {
          if candidateRange.upperBound >= b[bIndex].upperBound {
            bIndex += 1
          } else {
            candidateRange = candidateRange.lowerBound..<b[bIndex].upperBound
            bIndex += 1
            swap(&a, &b)
            swap(&aIndex, &bIndex)
          }
        }

        result.append(candidateRange)
      }

      if aIndex < a.endIndex {
        result.append(contentsOf: a[aIndex...])
      } else if bIndex < b.endIndex {
        result.append(contentsOf: b[bIndex...])
      }

      return Self(_ranges: result)
    }
  }

  extension RangeSet.Ranges: Sequence {
    typealias Element = Range<UInt>
    typealias Iterator = IndexingIterator<Self>
  }

  extension RangeSet.Ranges: Collection {
    typealias Index = Int
    typealias Indices = Range<Index>
    typealias SubSequence = Slice<Self>

    var startIndex: Index {
      0
    }

    var endIndex: Index {
      _storage.count
    }

    var count: Int {
      self.endIndex
    }

    subscript(i: Index) -> Element {
      _storage[i]
    }
  }

  extension RangeSet.Ranges: RandomAccessCollection {}

  extension RangeSet.Ranges: Equatable {
    static func == (left: Self, right: Self) -> Bool {
      left._storage == right._storage
    }
  }

  private struct _Pair<Element>: RandomAccessCollection {
    internal var pair: (first: Element, second: Element)

    internal init(_ first: Element, _ second: Element) {
      self.pair = (first, second)
    }

    internal var startIndex: Int { 0 }
    internal var endIndex: Int { 2 }

    internal subscript(position: Int) -> Element {
      get {
        switch position {
        case 0: return pair.first
        case 1: return pair.second
        default: preconditionFailure("Index is out of range")
        }
      }
    }
  }

  extension Collection {
    fileprivate func _partitioningIndex(
      where predicate: (Element) throws -> Bool
    ) rethrows -> Index {
      var n = count
      var l = startIndex

      while n > 0 {
        let half = n / 2
        let mid = index(l, offsetBy: half)
        if try predicate(self[mid]) {
          n = half
        } else {
          l = index(after: mid)
          n -= half + 1
        }
      }
      return l
    }
  }
#endif
