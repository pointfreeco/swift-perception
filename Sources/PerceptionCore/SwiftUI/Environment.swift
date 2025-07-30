#if canImport(SwiftUI)
  import SwiftUI

  extension Environment {
    /// Creates an environment property to read a perceptible object from the environment.
    ///
    /// > Important: This is a back-port of SwiftUI's `Environment.init` that takes a perceptible
    /// > object.
    ///
    /// - Parameter objectType: The type of the `Perceptible` object to read from the environment.
    @_disfavoredOverload
    public init(_ objectType: Value.Type) where Value: AnyObject & Perceptible {
      self.init(\.[unwrap: \Value.self])
    }

    /// Creates an environment property to read a perceptible object from the environment, returning
    /// `nil` if no corresponding object has been set in the current view's environment.
    ///
    /// > Important: This is a back-port of SwiftUI's `Environment.init` that takes a perceptible
    /// > object.
    ///
    /// - Parameter objectType: The type of the `Perceptible` object to read from the environment.
    @_disfavoredOverload
    public init<T: AnyObject & Perceptible>(_ objectType: T.Type) where Value == T? {
      self.init(\.[\T.self])
    }
  }

  extension View {
    /// Places a perceptible object in the view’s environment.
    ///
    /// > Important: This is a back-port of SwiftUI's `View.environment` that takes a perceptible
    /// > object.
    ///
    /// - Parameter object: The object to set for this object's type in the environment, or `nil` to
    ///   clear an object of this type from the environment.
    /// - Returns: A view that has the specified object in its environment.
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

    fileprivate subscript<T: Perceptible>(unwrap _: KeyPath<T, T>) -> T {
      get {
        guard let object = self[\T.self] else {
          fatalError(
            """
            No perceptible object of type \(T.self) found. A View.environment(_:) for \(T.self) \
            may be missing as an ancestor of this view.
            """
          )
        }
        return object
      }
      set { self[\T.self] = newValue }
    }
  }
#endif
