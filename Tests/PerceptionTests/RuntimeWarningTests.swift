#if DEBUG && canImport(SwiftUI)
  import Combine
  import Perception
  import SwiftUI
  import XCTest

  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  final class RuntimeWarningTests: XCTestCase {
    @MainActor
    func testNotInPerceptionBody() {
      let model = Model()
      model.count += 1
      XCTAssertEqual(model.count, 1)
    }

    @MainActor
    func testInPerceptionBody_NotInSwiftUIBody() {
      let model = Model()
      _PerceptionLocals.$isInPerceptionTracking.withValue(true) {
        _ = model.count
      }
    }

    @MainActor
    func testNotInPerceptionBody_InSwiftUIBody() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text(expectRuntimeWarning { self.model.count }.description)
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testNotInPerceptionBody_InSwiftUIBody_Wrapper() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Wrapper {
            Text(expectRuntimeWarning { self.model.count }.description)
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testInPerceptionBody_InSwiftUIBody_Wrapper() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            Wrapper {
              Text(self.model.count.description)
            }
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testInPerceptionBody_InSwiftUIBody() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            Text(self.model.count.description)
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testNotInPerceptionBody_SwiftUIBinding() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Form {
            TextField("", text: expectRuntimeWarning { self.$model.text })
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testInPerceptionBody_SwiftUIBinding() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          WithPerceptionTracking {
            TextField("", text: self.$model.text)
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testNotInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        @State var model = Model(
          list: [
            Model(count: 1),
            Model(count: 2),
            Model(count: 3),
          ]
        )
        var body: some View {
          ForEach(expectRuntimeWarning { model.list }) { model in
            Text(expectRuntimeWarning { model.count }.description)
          }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testInnerInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        @State var model = Model(
          list: [
            Model(count: 1),
            Model(count: 2),
            Model(count: 3),
          ]
        )
        var body: some View {
          ForEach(expectRuntimeWarning { model.list }) { model in
            WithPerceptionTracking {
              Text(model.count.description)
            }
          }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testOuterInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        @State var model = Model(
          list: [
            Model(count: 1),
            Model(count: 2),
            Model(count: 3),
          ]
        )
        var body: some View {
          WithPerceptionTracking {
            ForEach(model.list) { model in
              Text(expectRuntimeWarning { model.count }.description)
            }
          }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testOuterAndInnerInPerceptionBody_ForEach() async throws {
      struct FeatureView: View {
        @State var model = Model(
          list: [
            Model(count: 1),
            Model(count: 2),
            Model(count: 3),
          ]
        )
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

      try await self.render(FeatureView())
    }

    @MainActor
    func testNotInPerceptionBody_Sheet() async throws {
      struct FeatureView: View {
        @State var model = Model(child: Model())
        var body: some View {
          Text("Parent")
            .sheet(item: expectRuntimeWarning { $model.child }) { child in
              Text(expectRuntimeWarning { child.count }.description)
            }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testInnerInPerceptionBody_Sheet() async throws {
      struct FeatureView: View {
        @State var model = Model(child: Model())
        var body: some View {
          Text("Parent")
            .sheet(item: expectRuntimeWarning { $model.child }) { child in
              WithPerceptionTracking {
                Text(child.count.description)
              }
            }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testOuterInPerceptionBody_Sheet() async throws {
      struct FeatureView: View {
        @State var model = Model(child: Model())
        var body: some View {
          WithPerceptionTracking {
            Text("Parent")
              .sheet(item: $model.child) { child in
                Text(expectRuntimeWarning { child.count }.description)
              }
          }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testOuterAndInnerInPerceptionBody_Sheet() async throws {
      struct FeatureView: View {
        @State var model = Model(child: Model())
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

      try await self.render(FeatureView())
    }

    @MainActor
    func testActionClosure() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onAppear { _ = self.model.count }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testActionClosure_CallMethodWithArguments() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onAppear { _ = foo(42) }
        }
        func foo(_: Int) -> Bool {
          _ = self.model.count
          return true
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testActionClosure_WithArguments() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onReceive(Just(1)) { _ in
              _ = self.model.count
            }
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testActionClosure_WithArguments_ImplicitClosure() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onReceive(Just(1), perform: self.foo)
        }
        func foo(_: Int) {
          _ = self.model.count
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testImplicitActionClosure() async throws {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onAppear(perform: foo)
        }
        func foo() {
          _ = self.model.count
        }
      }

      try await self.render(FeatureView())
    }

    @MainActor
    func testRegistrarDisablePerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        let registrar = PerceptionRegistrar(isPerceptionCheckingEnabled: false)
        var body: some View {
          let _ = registrar.access(model, keyPath: \.count)
          Text("Hi")
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testGlobalDisablePerceptionTracking() async throws {
      let previous = Perception.isPerceptionCheckingEnabled
      Perception.isPerceptionCheckingEnabled = false
      defer { Perception.isPerceptionCheckingEnabled = previous }

      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text(model.count.description)
        }
      }
      try await self.render(FeatureView())
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
          self.model = Model(list: [self.childModel])
        }
        var body: some View {
          VStack {
            ChildView(model: self.childModel)
            Text(expectRuntimeWarning { childModel.count }.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await self.render(FeatureView())
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
          self.model = Model(list: [self.childModel])
        }
        var body: some View {
          WithPerceptionTracking {
            ChildView(model: self.childModel)
            Text(childModel.count.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await self.render(FeatureView())
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
          self.model = Model(list: [self.childModel])
        }
        var body: some View {
          VStack {
            ChildView(model: self.childModel)
            Text(expectRuntimeWarning { childModel.count }.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await self.render(FeatureView())
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
          self.model = Model(list: [self.childModel])
        }
        var body: some View {
          WithPerceptionTracking {
            ChildView(model: self.childModel)
            Text(childModel.count.description)
          }
          .onAppear { let _ = childModel.count }
        }
      }

      try await self.render(FeatureView())
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
      try await self.render(FeatureView())
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
      try await self.render(FeatureView())
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
      try await self.render(FeatureView())
    }

    @MainActor
    func testGeometryReader_WithoutPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            GeometryReader { _ in
              Text(expectRuntimeWarning { self.model.count }.description)
            }
          }
        }
      }
      try await self.render(FeatureView())
    }

    @MainActor
    func testGeometryReader_WithProperPerceptionTracking() async throws {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          GeometryReader { _ in
            WithPerceptionTracking {
              Text(self.model.count.description)
            }
          }
        }
      }
      try await self.render(FeatureView())
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
            Text(expectRuntimeWarning { self.model.count }.description)
          }
        }
      }
      try await self.render(FeatureView())
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
      try await self.render(FeatureView())
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
      try await self.render(FeatureView())
    }

    @MainActor
    private func render(_ view: some View) async throws  {
      let image = ImageRenderer(content: view).cgImage
      _ = image
      try await Task.sleep(for: .seconds(0.1))
    }
  }

  private func expectRuntimeWarning<R>(failingBlock: () -> R) -> R {
    XCTExpectFailure(failingBlock: failingBlock) {
      $0.compactDescription == """
        failed - Perceptible state was accessed but is not being tracked. Track changes to state \
        by wrapping your view in a 'WithPerceptionTracking' view. This must also be done for any \
        escaping, trailing closures, such as 'GeometryReader', `LazyVStack` (and all lazy \
        views), navigation APIs ('sheet', 'popover', 'fullScreenCover', etc.), and others.
        """
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
#endif
