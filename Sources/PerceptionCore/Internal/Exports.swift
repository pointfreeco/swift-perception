#if canImport(Observation)
  @_exported import Observation
#else
  @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
  public protocol Observable {}
#endif
