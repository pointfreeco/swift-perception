import Foundation

/// Globally enable or disable perception checks.
///
/// The library performs certain runtime checks to make sure that the tools are being used
/// correctly. In particular, view bodies must be wrapped in the ``WithPerceptionTracking`` view
/// in order for observation to be properly tracked. If the library detects state accessed outside
/// ``withPerceptionTracking(_:onChange:)``, a perception check is done to detect if this access
/// occurred in a SwiftUI view, and a runtime warning is triggered to let you know there is
/// something to fix.
///
/// This check only happens in `DEBUG` builds, and so it does not affect App Store releases of your
/// app. However, the checks can sometimes be costly and slow down your app in development if you
/// frequently access state outside of observable contexts. To fully disable the checks, you can
/// set this boolean to `false`.
///
/// > Warning: Turn off perception checks at your own peril. Without them it is much easier to
/// > introduce broken features to pre-observation platforms.
@available(
  iOS, deprecated: 17, message: "'isPerceptionCheckingEnabled' is no longer needed in iOS 17+."
)
@available(
  macOS, deprecated: 14, message: "'isPerceptionCheckingEnabled' is no longer needed in macOS 14+."
)
@available(
  watchOS, deprecated: 10,
  message: "'isPerceptionCheckingEnabled' is no longer needed in watchOS 10+."
)
@available(
  tvOS, deprecated: 17, message: "'isPerceptionCheckingEnabled' is no longer needed in tvOS 17+."
)
public var isPerceptionCheckingEnabled: Bool {
  get { perceptionChecking.withCriticalRegion(\.self) }
  set { perceptionChecking.withCriticalRegion { $0 = newValue } }
}

#if DEBUG && canImport(SwiftUI)
  private let perceptionChecking = _ManagedCriticalState(true)
#else
  private let perceptionChecking = _ManagedCriticalState(false)
#endif
