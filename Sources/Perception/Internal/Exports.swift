#if canImport(Observation)
  @_exported import Observation
  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  public typealias _Observable = Observation.Observable
#else
  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  public protocol _Observable {}
#endif
