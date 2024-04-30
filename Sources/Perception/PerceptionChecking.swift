import Foundation

public var isPerceptionCheckingEnabled: Bool {
  get { perceptionChecking.isPerceptionCheckingEnabled }
  set { perceptionChecking.isPerceptionCheckingEnabled = newValue }
}

public var forcePerceptionChecking: Bool {
  get { perceptionChecking.forcePerceptionChecking }
  set { perceptionChecking.forcePerceptionChecking = newValue }
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
    var forcePerceptionChecking: Bool {
      get {
        lock.lock()
        defer { lock.unlock() }
        return _forcePerceptionChecking
      }
      set {
        lock.lock()
        defer { lock.unlock() }
        _forcePerceptionChecking = newValue
      }
    }
  let lock = NSLock()
  var _forcePerceptionChecking = false
  #if DEBUG
    var _isPerceptionCheckingEnabled = true
  #else
    var _isPerceptionCheckingEnabled = false
  #endif
}
