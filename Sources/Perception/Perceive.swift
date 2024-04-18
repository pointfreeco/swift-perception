#if canImport(ObjectiveC)
import ObjectiveC

extension NSObject {
  /// Observe access to properties of a `@Perceptible` or `@Observable` object.
  ///
  /// This tool allows you to set up an observation loop so that you can access fields from an
  /// observable model in order to populate your view, and also automatically track changes to
  /// any accessed fields so that the view is always up-to-date.
  ///
  /// It is most useful when dealing with non-SwiftUI views, such as UIKit views and controller.
  /// You can invoke the ``observe(_:)`` method a single time in the `viewDidLoad` and update all
  /// the view elements:
  ///
  /// ```swift
  /// override func viewDidLoad() {
  ///   super.viewDidLoad()
  ///
  ///   let countLabel = UILabel()
  ///   let incrementButton = UIButton(primaryAction: .init { _ in
  ///     store.send(.incrementButtonTapped)
  ///   })
  ///
  ///   perceive { [weak self] in
  ///     guard let self
  ///     else { return }
  ///
  ///     countLabel.text = "\(store.count)"
  ///   }
  /// }
  /// ```
  ///
  /// This closure is immediately called, allowing you to set the initial state of your UI
  /// components from the feature's state. And if the `count` property in the feature's state is
  /// ever mutated, this trailing closure will be called again, allowing us to update the view
  /// again.
  ///
  /// Generally speaking you can usually have a single ``perceive(_:)`` in the entry point of your
  /// view, such as `viewDidLoad` for `UIViewController`. This works even if you have many UI
  /// components to update:
  ///
  /// ```swift
  /// override func viewDidLoad() {
  ///   super.viewDidLoad()
  ///
  ///   perceive { [weak self] in
  ///     guard let self
  ///     else { return }
  ///
  ///     countLabel.isHidden = store.isObservingCount
  ///     if !countLabel.isHidden {
  ///       countLabel.text = "\(store.count)"
  ///     }
  ///     factLabel.text = store.fact
  ///   }
  /// }
  /// ```
  ///
  /// This does mean that you may execute the line `factLabel.text = store.fact` even when something
  /// unrelated changes, such as `store.count`, but that is typically OK for simple properties of
  /// UI components. It is not a performance problem to repeatedly set the `text` of a label or
  /// the `isHidden` of a button.
  ///
  /// However, if there is heavy work you need to perform when state changes, then it is best to
  /// put that in its own ``perceive(_:)``. For example, if you needed to reload a table view or
  /// collection view when a collection changes:
  ///
  /// ```swift
  /// override func viewDidLoad() {
  ///   super.viewDidLoad()
  ///
  ///   perceive { [weak self] in
  ///     guard let self
  ///     else { return }
  ///
  ///     self.dataSource = store.items
  ///     self.tableView.reloadData()
  ///   }
  /// }
  /// ```
  ///
  /// ## Navigation
  ///
  /// The ``perceive(_:)`` method makes it easy to drive navigation from state. To do so you need
  /// a reference to the controller that you are presenting (held as an optional), and when state
  /// becomes non-`nil` you assign and present the controller, and when state becomes `nil` you
  /// dismiss the controller and `nil` out the reference.
  ///
  /// For example, if your feature's state holds onto alert state, then an alert can be presented
  /// and dismissed with the following:
  ///
  /// ```swift
  /// override func viewDidLoad() {
  ///   super.viewDidLoad()
  ///
  ///   var alertController: UIAlertController?
  ///
  ///   perceive { [weak self] in
  ///     guard let self
  ///     else { return }
  ///
  ///     if
  ///       let store = store.scope(state: \.alert, action: \.alert),
  ///       alertController == nil
  ///     {
  ///       alertController = UIAlertController(store: store)
  ///       present(alertController!, animated: true, completion: nil)
  ///     } else if store.alert == nil, alertController != nil {
  ///       alertController?.dismiss(animated: true)
  ///       alertController = nil
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Here we are using the ``Store/scope(state:action:)-36e72`` operator for optional state in
  /// order to detect when the `alert` state flips from `nil` to non-`nil` and vice-versa.
  ///
  /// ## Cancellation
  ///
  /// The method returns a ``PerceptionToken`` that can be used to cancel observation. For example,
  /// if you only want to observe while a view controller is visible, you can start observation in
  /// the `viewWillAppear` and then cancel observation in the `viewWillDisappear`:
  ///
  /// ```swift
  /// var token: PerceptionToken?
  ///
  /// func viewWillAppear() {
  ///   super.viewWillAppear()
  ///   self.token = perceive { [weak self] in
  ///     // ...
  ///   }
  /// }
  /// func viewWillDisappear() {
  ///   super.viewWillDisappear()
  ///   self.token?.cancel()
  /// }
  /// ```
  @MainActor
  @discardableResult
  public func perceive(_ apply: @escaping () -> Void) -> PerceptionToken {
    let token = Perception.perceive(apply)
    self.tokens.insert(token)
    return token
  }

  fileprivate var tokens: Set<PerceptionToken> {
    get {
      (objc_getAssociatedObject(self, tokensHandle) as? Set<PerceptionToken>) ?? []
    }
    set {
      objc_setAssociatedObject(
        self,
        tokensHandle,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}

private let tokensHandle = malloc(1)!
#endif

@MainActor
public func perceive(_ apply: @escaping () -> Void) -> PerceptionToken {
//  if PerceiveLocals.isApplying {
//    runtimeWarn(
//      """
//      A "perceive" was called from another "perceive" closure, which can lead to \
//      over-observation and unintended side effects.
//
//      Avoid nested closures by moving child observation into their own lifecycle methods.
//      """
//    )
//  }
  let token = PerceptionToken()
  // NB: This is safe because `onChange` is only ever called on the main thread.
  let apply = UncheckedSendable(apply)
  @Sendable func onChange() {
    guard !token.isCancelled
    else { return }

    withPerceptionTracking(apply.value) {
      Task { @MainActor in
        guard !token.isCancelled
        else { return }
//        PerceiveLocals.$isApplying.withValue(true) {
          onChange()
//        }
      }
    }
  }
  onChange()
  return token
}

/// A token for cancelling observation created with ``ObjectiveC/NSObject/perceive(_:)``.
public final class PerceptionToken: Hashable, Sendable {
  private let _isCancelled = _ManagedCriticalState(false)
  fileprivate var isCancelled: Bool {
    self._isCancelled.withCriticalRegion { $0 }
  }

  /// Cancels observation that was created with ``ObjectiveC/NSObject/perceive(_:)``.
  ///
  /// > Note: This cancellation is lazy and cooperative. It does not cancel the observation
  /// immediately, but rather next time a change is detected by ``ObjectiveC/NSObject/perceive(_:)``
  /// it will cease any future observation.
  public func cancel() {
    self._isCancelled.withCriticalRegion { $0 = true }
  }

  public func store(in tokens: inout Set<PerceptionToken>) {
    tokens.insert(self)
  }

  public func store(in tokens: inout some RangeReplaceableCollection<PerceptionToken>) {
    tokens.append(self)
  }

  deinit {
    self.cancel()
  }

  public static func == (lhs: PerceptionToken, rhs: PerceptionToken) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

private enum PerceiveLocals {
  @TaskLocal static var isApplying = false
}
