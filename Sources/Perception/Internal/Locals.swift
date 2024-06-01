@available(iOS, deprecated: 17)
@available(macOS, deprecated: 14)
@available(tvOS, deprecated: 17)
@available(visionOS, deprecated: 9999)
@available(watchOS, deprecated: 10)
public enum _PerceptionLocals {
  @TaskLocal public static var isInPerceptionTracking = false
  @TaskLocal public static var skipPerceptionChecking = false
}
