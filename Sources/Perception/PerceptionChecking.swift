import Foundation

public var isPerceptionCheckingEnabled: Bool {
  get { perceptionChecking.isPerceptionCheckingEnabled }
  set { perceptionChecking.isPerceptionCheckingEnabled = newValue }
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
