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

    // Parse Mach-O load commands to get all segment address ranges
    private func getMachOSegmentRanges(header: UnsafePointer<mach_header>, slide: Int) -> [(UInt, UInt)] {
      var ranges: [(UInt, UInt)] = []
      
      #if arch(x86_64) || arch(arm64)
        let header64 = header.withMemoryRebound(to: mach_header_64.self, capacity: 1) { $0.pointee }
        var commandPtr = UnsafeRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        
        for _ in 0..<header64.ncmds {
          let cmd = commandPtr.load(as: load_command.self)
          if cmd.cmd == LC_SEGMENT_64 {
            let segment = commandPtr.load(as: segment_command_64.self)
            // Only include segments with actual size
            if segment.vmsize > 0 {
              let start = UInt(bitPattern: Int(segment.vmaddr) + slide)
              let end = UInt(bitPattern: Int(segment.vmaddr + segment.vmsize) + slide)
              ranges.append((start, end))
            }
          }
          commandPtr = commandPtr.advanced(by: Int(cmd.cmdsize))
        }
      #else
        let header32 = header.pointee
        var commandPtr = UnsafeRawPointer(header).advanced(by: MemoryLayout<mach_header>.size)
        
        for _ in 0..<header32.ncmds {
          let cmd = commandPtr.load(as: load_command.self)
          if cmd.cmd == LC_SEGMENT {
            let segment = commandPtr.load(as: segment_command.self)
            if segment.vmsize > 0 {
              let start = UInt(bitPattern: Int(segment.vmaddr) + slide)
              let end = UInt(bitPattern: Int(segment.vmaddr + segment.vmsize) + slide)
              ranges.append((start, end))
            }
          }
          commandPtr = commandPtr.advanced(by: Int(cmd.cmdsize))
        }
      #endif
      
      return ranges
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
        // Check return addresses against AttributeGraph segment ranges.
        // Parse Mach-O segments to get exact loaded address ranges.
        // This avoids expensive dladdr()/findClosestSymbol() calls.
        // See: https://mjtsai.com/blog/2025/10/03/spamsieve-3-2-1/
        
        // Find AttributeGraph segment address ranges
        var attributeGraphRanges: [(UInt, UInt)] = []
        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
          guard let imageName = _dyld_get_image_name(i) else { continue }
          let name = String(cString: imageName)
          if name.contains("AttributeGraph") {
            guard let header = _dyld_get_image_header(i) else { continue }
            let slide = _dyld_get_image_vmaddr_slide(i)
            
            // Parse Mach-O to get individual segment ranges
            let segmentRanges = getMachOSegmentRanges(header: header, slide: slide)
            attributeGraphRanges.append(contentsOf: segmentRanges)
          }
        }
        
        // Check if any return address is in AttributeGraph segment ranges
        let result = Thread.callStackReturnAddresses.contains { address in
          let addressValue = UInt(bitPattern: address.pointerValue)
          return attributeGraphRanges.contains { start, end in
            addressValue >= start && addressValue < end
          }
        }
        
        perceptionChecks[location] = result
        return result
      }
    }
  }
#endif
