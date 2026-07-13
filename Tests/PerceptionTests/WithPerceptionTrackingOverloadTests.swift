#if canImport(SwiftUI)
  import Perception
  import SwiftUI

  // Compile-time test for https://github.com/swiftlang/swift/issues/90628:
  // this file fails to build on the Xcode 27 beta toolchain without
  // '@_disfavoredOverload' on the base 'WithPerceptionTracking' initializer.
  @MainActor
  private protocol Coordinator: AnyObject {
    associatedtype Root: View
    @ViewBuilder func buildRoot() -> Root
  }

  @Perceptible
  private final class FeatureCoordinator: Coordinator {
    var count = 0

    func buildRoot() -> some View {
      WithPerceptionTracking { [self] in
        Text("\(count)")
      }
    }
  }
#endif
