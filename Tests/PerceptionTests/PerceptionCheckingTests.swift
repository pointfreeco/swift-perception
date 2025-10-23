#if DEBUG && canImport(SwiftUI)
  import Combine
  import Perception
  import SwiftUI
  import XCTest

  @available(iOS, introduced: 16, deprecated: 17)
  @available(macOS, introduced: 13, deprecated: 14)
  @available(tvOS, introduced: 16, deprecated: 17)
  @available(watchOS, introduced: 9, deprecated: 10)
  final class PerceptionCheckingTests: XCTestCase {
    override func setUp() async throws {
      guard !deploymentTargetIncludesObservation() else {
        throw XCTSkip(
          """
          PercecptionTests were built against a deployment target too recent for perception checking.

          To force these tests to run on macOS, you can override the target OS version explicitly as:

            swift test -Xswiftc -target -Xswiftc arm64-apple-macosx13.0
          """
        )
      }
    }

    @MainActor
    func testNotInPerceptionBody() {
      let model = Model()
      model.count += 1
      XCTAssertEqual(model.count, 1)
    }

    @MainActor
    func testNotInPerceptionBody_InSwiftUIBody() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text(expectRuntimeWarning { model.count }.description)
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testNotInPerceptionBody_InSwiftUIBody_Wrapper() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Wrapper {
            Text(expectRuntimeWarning { model.count }.description)
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testInPerceptionBody_InSwiftUIBody_Wrapper() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            Wrapper {
              Text(model.count.description)
            }
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testInPerceptionBody_InSwiftUIBody() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            Text(model.count.description)
          }
        }
      }
      try await render(FeatureView())
    }

    #if !os(macOS)
      @MainActor
      func testNotInPerceptionBody_SwiftUIBinding() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            Form {
              TextField("", text: expectRuntimeWarning { $model.text })
            }
          }
        }
        try await render(FeatureView(model: Model()))
      }
    #endif

    #if !os(macOS)
      @MainActor
      func testInPerceptionBody_SwiftUIBinding() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            WithPerceptionTracking {
              TextField("", text: $model.text)
            }
          }
        }
        try await render(FeatureView(model: Model()))
      }
    #endif

    @MainActor
    func testNotInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          ForEach(expectRuntimeWarning { model.list }) { model in
            Text(expectRuntimeWarning { model.count }.description)
          }
        }
      }

      try await render(
        FeatureView(
          model: Model(
            list: [
              Model(count: 1),
              Model(count: 2),
              Model(count: 3),
            ]
          )
        )
      )
    }

    @MainActor
    func testInnerInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          ForEach(expectRuntimeWarning { model.list }) { model in
            WithPerceptionTracking {
              Text(model.count.description)
            }
          }
        }
      }

      try await render(
        FeatureView(
          model: Model(
            list: [
              Model(count: 1),
              Model(count: 2),
              Model(count: 3),
            ]
          )
        )
      )
    }

    @MainActor
    func testOuterInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          WithPerceptionTracking {
            ForEach(model.list) { model in
              Text(expectRuntimeWarning { model.count }.description)
            }
          }
        }
      }

      try await render(
        FeatureView(
          model: Model(
            list: [
              Model(count: 1),
              Model(count: 2),
              Model(count: 3),
            ]
          )
        )
      )
    }

    @MainActor
    func testOuterAndInnerInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          WithPerceptionTracking {
            ForEach(model.list) { model in
              WithPerceptionTracking {
                Text(model.count.description)
              }
            }
          }
        }
      }

      try await render(
        FeatureView(
          model: Model(
            list: [
              Model(count: 1),
              Model(count: 2),
              Model(count: 3),
            ]
          )
        )
      )
    }

    #if !os(macOS)
      @MainActor
      func testNotInPerceptionBody_Sheet() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            Text("Parent")
              .sheet(item: expectRuntimeWarning { $model.child }) { child in
                Text(expectRuntimeWarning { child.count }.description)
              }
          }
        }
        // NB: This failure is triggered out-of-body by the binding.
        XCTExpectFailure { $0.compactDescription.contains("Perceptible state was accessed") }
        try await render(FeatureView(model: Model(child: Model())))
      }
    #endif

    #if !os(macOS)
      @MainActor
      func testInnerInPerceptionBody_Sheet() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            Text("Parent")
              .sheet(item: expectRuntimeWarning { $model.child }) { child in
                WithPerceptionTracking {
                  Text(child.count.description)
                }
              }
          }
        }
        // NB: This failure is triggered out-of-body by the binding.
        XCTExpectFailure { $0.compactDescription.contains("Perceptible state was accessed") }
        try await render(FeatureView(model: Model(child: Model())))
      }
    #endif

    #if !os(macOS)
      @MainActor
      func testOuterInPerceptionBody_Sheet() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            WithPerceptionTracking {
              Text("Parent")
                .sheet(item: $model.child) { child in
                  Text(expectRuntimeWarning { child.count }.description)
                }
            }
          }
        }

        try await render(FeatureView(model: Model(child: Model())))
      }
    #endif

    #if !os(macOS)
      @MainActor
      func testOuterAndInnerInPerceptionBody_Sheet() async throws {
        struct FeatureView: View {
          @Perception.Bindable var model: Model
          var body: some View {
            WithPerceptionTracking {
              Text("Parent")
                .sheet(item: $model.child) { child in
                  WithPerceptionTracking {
                    Text(child.count.description)
                  }
                }
            }
          }
        }

        try await render(FeatureView(model: Model(child: Model())))
      }
    #endif

    @MainActor
    func testActionClosure() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          Text("Hi")
            .onAppear { _ = model.count }
        }
      }

      try await render(FeatureView(model: Model()))
    }

    @MainActor
    func testActionClosure_CallMethodWithArguments() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          Text("Hi")
            .onAppear { _ = foo(42) }
        }
        func foo(_: Int) -> Bool {
          _ = model.count
          return true
        }
      }

      try await render(FeatureView(model: Model()))
    }

    @MainActor
    func testActionClosure_WithArguments() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          Text("Hi")
            .onReceive(Just(1)) { _ in
              _ = model.count
            }
        }
      }

      try await render(FeatureView(model: Model()))
    }

    @MainActor
    func testActionClosure_WithArguments_ImplicitClosure() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          Text("Hi")
            .onReceive(Just(1), perform: foo)
        }
        func foo(_: Int) {
          _ = model.count
        }
      }

      try await render(FeatureView(model: Model()))
    }

    @MainActor
    func testImplicitActionClosure() async throws {
      struct FeatureView: View {
        let model: Model
        var body: some View {
          Text("Hi")
            .onAppear(perform: foo)
        }
        func foo() {
          _ = model.count
        }
      }

      try await render(FeatureView(model: Model()))
    }

    @MainActor
    func testParentAccessingChildState_ParentNotObserving_ChildObserving() async throws {
      struct ChildView: View {
        let model: Model
        var body: some View {
          WithPerceptionTracking {
            Text(model.count.description)
              .onAppear { let _ = model.count }
          }
        }
      }
      struct FeatureView: View {
        let model: Model
        let childModel: Model
        init() {
          self.childModel = Model()
          model = Model(list: [self.childModel])
        }
        var body: some View {
          VStack {
            ChildView(model: self.childModel)
            Text(expectRuntimeWarning { childModel.count }.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await render(FeatureView())
    }

    @MainActor
    func testParentAccessingChildState_ParentObserving_ChildNotObserving() async throws {
      struct ChildView: View {
        let model: Model
        var body: some View {
          Text(expectRuntimeWarning { model.count }.description)
            .onAppear { let _ = model.count }
        }
      }
      struct FeatureView: View {
        let model: Model
        let childModel: Model
        init() {
          self.childModel = Model()
          model = Model(list: [self.childModel])
        }
        var body: some View {
          WithPerceptionTracking {
            ChildView(model: self.childModel)
            Text(childModel.count.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await render(FeatureView())
    }

    @MainActor
    func testParentAccessingChildState_ParentNotObserving_ChildNotObserving() async throws {
      struct ChildView: View {
        let model: Model
        var body: some View {
          Text(expectRuntimeWarning { model.count }.description)
            .onAppear { let _ = model.count }
        }
      }
      struct FeatureView: View {
        let model: Model
        let childModel: Model
        init() {
          self.childModel = Model()
          model = Model(list: [self.childModel])
        }
        var body: some View {
          VStack {
            ChildView(model: self.childModel)
            Text(expectRuntimeWarning { childModel.count }.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await render(FeatureView())
    }

    @MainActor
    func testParentAccessingChildState_ParentObserving_ChildObserving() async throws {
      struct ChildView: View {
        let model: Model
        var body: some View {
          WithPerceptionTracking {
            Text(model.count.description)
              .onAppear { let _ = model.count }
          }
        }
      }
      struct FeatureView: View {
        let model: Model
        let childModel: Model
        init() {
          self.childModel = Model()
          model = Model(list: [self.childModel])
        }
        var body: some View {
          WithPerceptionTracking {
            ChildView(model: self.childModel)
            Text(childModel.count.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await render(FeatureView())
    }

    @MainActor
    func testAccessInOnAppearWithAsyncTask() async throws {
      @MainActor
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text("Hi")
            .onAppear {
              Task { @MainActor in _ = model.count }
            }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testAccessInOnAppearWithAsyncTask_Implicit() async throws {
      @MainActor
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text("Hi")
            .onAppear {
              Task(operation: self.perform)
            }
        }
        @Sendable
        func perform() async throws {
          _ = model.count
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testAccessInTask() async throws {
      @MainActor
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text("Hi")
            .task { @MainActor in
              _ = model.count
            }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testGeometryReader_WithoutPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            GeometryReader { _ in
              Text(expectRuntimeWarning { model.count }.description)
            }
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testGeometryReader_WithProperPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          GeometryReader { _ in
            WithPerceptionTracking {
              Text(model.count.description)
            }
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testGeometryReader_ComputedProperty_ImproperPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            content
          }
        }
        var content: some View {
          GeometryReader { _ in
            Text(expectRuntimeWarning { model.count }.description)
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testGeometryReader_NestedSuspendingClosure_ImproperPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          GeometryReader { _ in
            ZStack {}
              .task { @MainActor in _ = model.count }
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    func testGeometryReader_NestedActionClosure_ImproperPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          GeometryReader { _ in
            ZStack {}
              .onAppear { let _ = model.count }
          }
        }
      }
      try await render(FeatureView())
    }

    @MainActor
    private func render(_ view: some View) async throws {
      let image = ImageRenderer(content: view).cgImage
      _ = image
      try await Task.sleep(for: .seconds(0.1))
    }
  }

  private func expectRuntimeWarning<R>(failingBlock: () -> R) -> R {
    XCTExpectFailure(failingBlock: failingBlock) {
      $0.compactDescription.contains("Perceptible state was accessed")
    }
  }

  @Perceptible
  private class Model: Identifiable {
    var child: Model?
    var count: Int
    var list: [Model]
    var text: String

    init(
      child: Model? = nil,
      count: Int = 0,
      list: [Model] = [],
      text: String = ""
    ) {
      self.child = child
      self.count = count
      self.list = list
      self.text = text
    }
  }

  struct Wrapper<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
      self.content
    }
  }

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  private func deploymentTargetIncludesObservation() -> Bool { true }

  @_disfavoredOverload
  private func deploymentTargetIncludesObservation(_dummy: Void = ()) -> Bool { false }
#endif
