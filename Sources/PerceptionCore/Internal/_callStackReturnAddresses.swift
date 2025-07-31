#if DEBUG && canImport(SwiftUI)
  import Foundation
  @_transparent
  public var _callStackReturnAddresses: [NSNumber] {
    Thread.callStackReturnAddresses
  }
#endif
