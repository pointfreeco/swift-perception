#if canImport(SwiftUI)
  import SwiftUI

  /// A property wrapper type that supports creating bindings to the mutable properties of
  /// perceptible objects.
  ///
  /// A backport of SwiftUI's `Bindable` property wrapper.
  @available(iOS, introduced: 13, obsoleted: 17, message: "Use @Bindable without the 'Perception.' prefix.")
  @available(macOS, introduced: 10.15, obsoleted: 14, message: "Use @Bindable without the 'Perception.' prefix.")
  @available(tvOS, introduced: 13, obsoleted: 17, message: "Use @Bindable without the 'Perception.' prefix.")
  @available(watchOS, introduced: 6, obsoleted: 10, message: "Use @Bindable without the 'Perception.' prefix.")
  @available(visionOS, unavailable, message: "Use @Bindable without the 'Perception.' prefix.")
  @dynamicMemberLookup
  @propertyWrapper
  public struct Bindable<Value> {
    /// The wrapped object.
    public var wrappedValue: Value {
      get {
        wrappedValueBinding.wrappedValue
      }
      set {
        wrappedValueBinding.wrappedValue = newValue
      }
    }
    public let wrappedValueBinding: Binding<Value>

    /// The bindable wrapper for the object that creates bindings to its properties using dynamic
    /// member lookup.
    public var projectedValue: Bindable<Value> {
      self
    }

    /// Returns a binding to the value of a given key path.
    public subscript<Subject>(
      dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> where Value: AnyObject {
      self.wrappedValueBinding[dynamicMember: keyPath]
    }

    /// Creates a bindable object from an observable object.
    public init(wrappedValue: Value) where Value: AnyObject & Perceptible {
     // self.wrappedValue = wrappedValue
      var wrappedValue = wrappedValue
      self.wrappedValueBinding = Binding(
        get: { wrappedValue },
        set: { wrappedValue = $0 }
      )
    }

    /// Creates a bindable object from an observable object.
    public init(_ wrappedValue: Value) where Value: AnyObject & Perceptible {
      // self.wrappedValue = wrappedValue
      var wrappedValue = wrappedValue
      self.wrappedValueBinding = Binding(
        get: { wrappedValue },
        set: { wrappedValue = $0 }
      )
    }

    /// Creates a bindable from the value of another bindable.
    public init(projectedValue: Bindable<Value>) where Value: AnyObject & Perceptible {
      self = projectedValue
    }
  }

  @available(iOS, introduced: 13, obsoleted: 17)
  @available(macOS, introduced: 10.15, obsoleted: 14)
  @available(tvOS, introduced: 13, obsoleted: 17)
  @available(watchOS, introduced: 6, obsoleted: 10)
  extension Bindable: Identifiable where Value: Identifiable {
    /// The stable identity of the entity associated with this instance.
    public var id: Value.ID { self.wrappedValueBinding.wrappedValue.id }
  }

  @available(iOS, introduced: 13, obsoleted: 17)
  @available(macOS, introduced: 10.15, obsoleted: 14)
  @available(tvOS, introduced: 13, obsoleted: 17)
  @available(watchOS, introduced: 6, obsoleted: 10)
  extension Bindable: @unchecked Sendable where Value: Sendable {}
#endif
