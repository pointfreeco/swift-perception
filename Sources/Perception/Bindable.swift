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
    @ObservedObject fileprivate var observer: Observer<Value>

    /// The wrapped object.
    public var wrappedValue: Value {
      get { self.observer.object }
      set { self.observer.object = newValue }
    }

    /// The bindable wrapper for the object that creates bindings to its properties using dynamic
    /// member lookup.
    public var projectedValue: Bindable<Value> {
      self
    }

    /// Returns a binding to the value of a given key path.
    public subscript<Subject>(
      dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>
    ) -> Binding<Subject> where Value: AnyObject {
      withPerceptionTracking {
        self.$observer[dynamicMember: (\Observer.object).appending(path: keyPath)]
      } onChange: { [send = UncheckedSendable(self.observer.objectWillChange.send)] in
        send.value()
      }
    }

    /// Creates a bindable object from an observable object.
    public init(wrappedValue: Value) where Value: AnyObject & Perceptible {
      self.observer = Observer(wrappedValue)
    }

    /// Creates a bindable object from an observable object.
    public init(_ wrappedValue: Value) where Value: AnyObject & Perceptible {
      self.init(wrappedValue: wrappedValue)
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
  extension Bindable: Sendable where Value: Sendable {}

  private final class Observer<Object>: ObservableObject {
    var object: Object
    init(_ object: Object) {
      self.object = object
    }
  }
#endif
