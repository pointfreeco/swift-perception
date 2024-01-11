import SwiftUI

@available(iOS, deprecated: 17)
@available(macOS, deprecated: 14)
@available(tvOS, deprecated: 17)
@available(watchOS, deprecated: 10)
public enum _PerceptionLocals {
  @TaskLocal public static var isInPerceptionTracking = false
  @TaskLocal public static var skipPerceptionChecking = false
}

/// Observes changes to perceptible models.
///
/// Use this view to automatically subscribe to the changes of any fields in ``Perceptible()``
/// models used in the view. Typically you will install this view at the root of your view like
/// so:
///
/// ```swift
/// struct FeatureView: View {
///   let model: FeatureModel
///
///   var body: some View {
///     WithPerceptionTracking {
///       // ...
///     }
///   }
/// }
/// ```
///
/// You will also need to use ``WithPerceptionTracking`` in any escaping, trailing closures used in
/// SwiftUI's various navigation APIs, such as the sheet modifier:
///
/// ```swift
/// .sheet(isPresented: $isPresented) {
///   WithPerceptionTracking {
///     // Access to `model` in here will be properly observed.
///   }
/// }
/// ```
///
/// If a field of a `@Perceptible` model is accessed in a view while _not_ inside
/// ``WithPerceptionTracking``, then a runtime warning will helpfully be triggered:
///
/// > 🟣 Runtime Warning: Perceptible state was accessed but is not being tracked. Track changes to
/// > state by wrapping your view in a 'WithPerceptionTracking' view.
///
/// To debug this, expand the warning in the Issue Navigator of Xcode (cmd+5), and click through the
/// stack frames displayed to find the line in your view where you are accessing state without being
/// inside ``WithPerceptionTracking``.
@available(iOS, deprecated: 17, message: "Remove WithPerceptionTracking")
@available(macOS, deprecated: 14, message: "Remove WithPerceptionTracking")
@available(tvOS, deprecated: 17, message: "Remove WithPerceptionTracking")
@available(watchOS, deprecated: 10, message: "Remove WithPerceptionTracking")
@MainActor
public struct WithPerceptionTracking<Content: View>: View {
  @State var id = 0
  private let content: () -> Content
  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  public var body: Content {
    if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
      return _PerceptionLocals.$isInPerceptionTracking.withValue(true) {
        self.instrumentedBody()
      }
    } else {
      // NB: View will not re-render when 'id' changes unless we access it in the view.
      let _ = self.id
      return withPerceptionTracking {
        _PerceptionLocals.$isInPerceptionTracking.withValue(true) {
          self.instrumentedBody()
        }
      } onChange: {
        Task { @MainActor in
          self.id += 1
        }
      }
    }
  }

  private func instrumentedBody() -> Content {
    #if DEBUG
      return _PerceptionLocals.$isInPerceptionTracking.withValue(true) {
        self.content()
      }
    #else
      return self.content()
    #endif
  }
}
