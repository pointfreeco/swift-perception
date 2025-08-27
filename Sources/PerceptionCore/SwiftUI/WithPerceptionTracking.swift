#if canImport(SwiftUI)
  import SwiftUI

  /// A view that perceives changes to perceptible models.
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
  /// You will also need to use ``WithPerceptionTracking`` in any escaping, trailing closures used
  /// in SwiftUI's various navigation APIs, such as the sheet modifier:
  ///
  /// ```swift
  /// .sheet(isPresented: $isPresented) {
  ///   WithPerceptionTracking {
  ///     // Access to `model` in here will be properly observed.
  ///   }
  /// }
  /// ```
  ///
  /// > Tip: Other common escaping closures to be aware of:
  /// >
  /// >   * Reader views, such as `GeometryReader`, ScrollViewReader`, etc.
  /// >   * Lazy views such as `LazyVStack`, `LazyVGrid`, etc.
  /// >   * Navigation APIs, such as `sheet`, `popover`, `fullScreenCover`, `navigationDestination`,
  /// >     etc.
  ///
  /// If a field of a `@Perceptible` model is accessed in a view while _not_ inside
  /// ``WithPerceptionTracking``, then a runtime warning will helpfully be triggered:
  ///
  /// > Warning: Perceptible state was accessed but is not being tracked.
  ///
  /// To debug this, expand the warning in the Issue Navigator of Xcode (cmd+5), and click through
  /// the stack frames displayed to find the line in your view where you are accessing state without
  /// being inside ``WithPerceptionTracking``.
  ///
  /// > Important: In iOS 17+, etc., `WithPerceptionTracking` is a no-op and SwiftUI will use the
  /// > Observation framework instead. Be sure to test your application in all supported deployment
  /// > targets to catch potential differences in observation behavior.
  @available(
    iOS,
    deprecated: 17,
    message: "'WithPerceptionTracking' is no longer needed in iOS 17+."
  )
  @available(
    macOS,
    deprecated: 14,
    message: "'WithPerceptionTracking' is no longer needed in macOS 14+."
  )
  @available(
    watchOS,
    deprecated: 10,
    message: "'WithPerceptionTracking' is no longer needed in watchOS 10+."
  )
  @available(
    tvOS,
    deprecated: 17,
    message: "'WithPerceptionTracking' is no longer needed in tvOS 17+."
  )
  public struct WithPerceptionTracking<Content> {
    private enum _Content {
      case direct(Content)
      #if DEBUG
        case instrumented(() -> Content)
      #endif
      case tracked(() -> Content)

      init(_ content: @escaping () -> Content) {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *), !isObservationBeta {
          #if DEBUG
            self = .instrumented(content)
          #else
            self = .direct(content())
          #endif
        } else {
          self = .tracked(content)
        }
      }
    }

    @State var id = 0
    private let content: _Content

    public var body: Content {
      switch content {
      case .direct(let content):
        return content

      #if DEBUG
        case .instrumented(let content):
          return instrument(content)
      #endif

      case .tracked(let content):
        let _ = id
        return withPerceptionTracking(content, onChange: { id &+= 1 })
      }
    }

    public init(content: @escaping @autoclosure () -> Content) {
      self.content = _Content(content)
    }

    @_transparent
    @inline(__always)
    private func instrument(_ content: () -> Content) -> Content {
      #if DEBUG
        return _PerceptionLocals.$isInPerceptionTracking.withValue(true, operation: content)
      #else
        return content()
      #endif
    }
  }

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  extension WithPerceptionTracking: AccessibilityRotorContent
  where Content: AccessibilityRotorContent {
    public init(@AccessibilityRotorContentBuilder content: @escaping () -> Content) {
      self.init(content: content())
    }
  }

  @available(iOS 14, macOS 11, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension WithPerceptionTracking: Commands where Content: Commands {
    public init(@CommandsBuilder content: @escaping () -> Content) {
      self.init(content: content())
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension WithPerceptionTracking: CustomizableToolbarContent
  where Content: CustomizableToolbarContent {
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension WithPerceptionTracking: Scene where Content: Scene {
    public init(@SceneBuilder content: @escaping () -> Content) {
      self.init(content: content())
    }
  }

  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension WithPerceptionTracking: TableColumnContent where Content: TableColumnContent {
    public typealias TableRowValue = Content.TableRowValue
    public typealias TableColumnSortComparator = Content.TableColumnSortComparator
    public typealias TableColumnBody = Never

    public init<R, C>(@TableColumnBuilder<R, C> content: @escaping () -> Content)
    where R == Content.TableRowValue, C == Content.TableColumnSortComparator {
      self.init(content: content())
    }

    nonisolated public var tableColumnBody: Never {
      fatalError()
    }

    nonisolated public static func _makeContent(
      content: _GraphValue<WithPerceptionTracking<Content>>,
      inputs: _TableColumnInputs
    ) -> _TableColumnOutputs {
      Content._makeContent(content: content[\.body], inputs: inputs)
    }
  }

  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  extension WithPerceptionTracking: TableRowContent where Content: TableRowContent {
    public typealias TableRowValue = Content.TableRowValue
    public typealias TableRowBody = Never

    public init<R>(@TableRowBuilder<R> content: @escaping () -> Content)
    where R == Content.TableRowValue {
      self.init(content: content())
    }

    nonisolated public var tableRowBody: Never {
      fatalError()
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  extension WithPerceptionTracking: ToolbarContent where Content: ToolbarContent {
    public init(@ToolbarContentBuilder content: @escaping () -> Content) {
      self.init(content: content())
    }
  }

  extension WithPerceptionTracking: View where Content: View {
    public init(@ViewBuilder content: @escaping () -> Content) {
      self.init(content: content())
    }
  }

  #if canImport(Charts)
    import Charts

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    extension WithPerceptionTracking: ChartContent where Content: ChartContent {
      @_disfavoredOverload
      public init(@ChartContentBuilder content: @escaping () -> Content) {
        self.init(content: content())
      }
    }
  #endif
#endif
