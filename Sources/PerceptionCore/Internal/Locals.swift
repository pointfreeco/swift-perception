public enum _PerceptionLocals {
  @TaskLocal public static var skipPerceptionChecking = false

  #if DEBUG
    @available(iOS, deprecated: 17)
    @available(macOS, deprecated: 14)
    @available(watchOS, deprecated: 10)
    @available(tvOS, deprecated: 17)
    @TaskLocal public static var isInPerceptionTracking = false
  #endif
}
