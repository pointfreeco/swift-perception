#if canImport(SwiftUI)
  import Perception
  import SwiftUI

  // https://github.com/swiftlang/swift/issues/90628
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
