#if canImport(SwiftUI)
  import SwiftUI

  /// A property wrapper type that supports creating bindings to the mutable properties of
  /// perceptible objects.
  ///
  /// > Important: This is a back-port of SwiftUI's `Bindable` property wrapper.
  @available(
    iOS,
    introduced: 13,
    obsoleted: 17,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    macOS,
    introduced: 10.15,
    obsoleted: 14,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    tvOS,
    introduced: 13,
    obsoleted: 17,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    watchOS,
    introduced: 6,
    obsoleted: 10,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(visionOS, unavailable)
  @dynamicMemberLookup
  @propertyWrapper
  public struct Bindable<Value> {
    @ObservedObject fileprivate var observer: Observer<Value>

    /// The wrapped object.
    public var wrappedValue: Value {
      get { observer.object }
      set { observer.object = newValue }
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
      #if DEBUG && canImport(SwiftUI)
        func open<V: Perceptible>(_: V.Type) -> Binding<Subject> {
          ($observer as! ObservedObject<Observer<V>>.Wrapper).object[
            isPerceptionTracking: _PerceptionLocals.isInPerceptionTracking,
            keyPath: unsafeDowncast(keyPath, to: ReferenceWritableKeyPath<V, Subject>.self)
          ]
        }
        guard let valueType = Value.self as? any Perceptible.Type else { fatalError() }
        return open(valueType)
      #else
        $observer.object[dynamicMember: keyPath]
      #endif
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

  @available(visionOS, unavailable)
  extension Bindable: Identifiable where Value: Identifiable {
    public var id: Value.ID {
      wrappedValue.id
    }
  }

  @available(visionOS, unavailable)
  extension Bindable: Sendable where Value: Sendable {}

  private final class Observer<Object>: ObservableObject {
    var object: Object
    init(_ object: Object) {
      self.object = object
    }
  }

  extension Observer: Equatable where Object: AnyObject {
    static func == (lhs: Observer, rhs: Observer) -> Bool {
      lhs.object === rhs.object
    }
  }

  #if DEBUG
    extension Perceptible {
      fileprivate subscript<Member>(
        isPerceptionTracking isPerceptionTracking: Bool,
        keyPath keyPath: ReferenceWritableKeyPath<Self, Member>
      ) -> Member {
        get {
          _PerceptionLocals.$isInPerceptionTracking.withValue(isPerceptionTracking) {
            self[keyPath: keyPath]
          }
        }
        set {
          self[keyPath: keyPath] = newValue
        }
      }
    }
  #endif
#endif
