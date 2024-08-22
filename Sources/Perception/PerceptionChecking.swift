import Foundation

/// Globally enable or disable perception checks.
///
/// The library performs certain runtime checks to make sure that the tools are being used
/// correctly. In particular, view bodies must be wrapped in the ``WithPerceptionTracking`` view
/// in order for observation to be properly tracked. If the library detects state is accessed
/// without being inside ``WithPerceptionTracking``, a runtime warning is triggered to let you
/// know there is something to fix.
///
/// This check only happens in `DEBUG` builds, and so does not affect App Store releases of your
/// app. However, the checks can sometimes be costly and slow down your app in development. If
/// you wish to fully disable the checks, you can set this boolean to `false.`
public var isPerceptionCheckingEnabled: Bool {
  get { perceptionChecking.isPerceptionCheckingEnabled }
  set { perceptionChecking.isPerceptionCheckingEnabled = newValue }
}

public enum _PerceptionLocals {
  @TaskLocal public static var isInPerceptionTracking = false
  @TaskLocal public static var skipPerceptionChecking = false
}

private let perceptionChecking = PerceptionChecking()

private class PerceptionChecking: @unchecked Sendable {
  var isPerceptionCheckingEnabled: Bool {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _isPerceptionCheckingEnabled
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _isPerceptionCheckingEnabled = newValue
    }
  }
  let lock = NSLock()
  #if DEBUG
    var _isPerceptionCheckingEnabled = true
  #else
    var _isPerceptionCheckingEnabled = false
  #endif
}
