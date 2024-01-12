import SwiftUI

extension Environment {
  @available(iOS, introduced: 13, obsoleted: 17)
  @available(macOS, introduced: 10.15, obsoleted: 14)
  @available(tvOS, introduced: 13, obsoleted: 17)
  @available(watchOS, introduced: 6, obsoleted: 10)
  @available(visionOS, unavailable)
  @_disfavoredOverload
  public init(_ objectType: Value.Type) where Value: AnyObject & Perceptible {
    self.init(\.[unwrap: \Value.self])
  }

  @available(iOS, introduced: 13, obsoleted: 17)
  @available(macOS, introduced: 10.15, obsoleted: 14)
  @available(tvOS, introduced: 13, obsoleted: 17)
  @available(watchOS, introduced: 6, obsoleted: 10)
  @available(visionOS, unavailable)
  @_disfavoredOverload
  public init<T: AnyObject & Perceptible>(_ objectType: T.Type) where Value == T? {
    self.init(\.[\T.self])
  }
}

extension View {
  @available(iOS, introduced: 13, obsoleted: 17)
  @available(macOS, introduced: 10.15, obsoleted: 14)
  @available(tvOS, introduced: 13, obsoleted: 17)
  @available(watchOS, introduced: 6, obsoleted: 10)
  @available(visionOS, unavailable)
  @_disfavoredOverload
  public func environment<T: AnyObject & Perceptible>(_ object: T?) -> some View {
    self.environment(\.[\T.self], object)
  }
}

private struct PerceptibleKey<T: Perceptible>: EnvironmentKey {
  static var defaultValue: T? { nil }
}

extension EnvironmentValues {
  fileprivate subscript<T: Perceptible>(_: KeyPath<T, T>) -> T? {
    get { self[PerceptibleKey<T>.self] }
    set { self[PerceptibleKey<T>.self] = newValue }
  }
}

extension EnvironmentValues {
  fileprivate subscript<T: Perceptible>(unwrap _: KeyPath<T, T>) -> T {
    get {
      guard let object = self[\T.self] else {
        fatalError(
          """
          No perceptible object of type \(T.self) found. A View.environment(_:) for \(T.self) may \
          be missing as an ancestor of this view.
          """
        )
      }
      return object
    }
    set { self[\T.self] = newValue }
  }
}
