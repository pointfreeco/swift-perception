#if DEBUG
  import Combine
  import Perception
  import SwiftUI
  import XCTest

  @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
  @MainActor
  final class RuntimeWarningTests: XCTestCase {
    func testNotInPerceptionBody() {
      let model = Model()
      model.count += 1
      XCTAssertEqual(model.count, 1)
    }

    func testInPerceptionBody_NotInSwiftUIBody() {
      let model = Model()
      _PerceptionLocals.$isInPerceptionTracking.withValue(true) {
        _ = model.count
      }
    }

    func testNotInPerceptionBody_InSwiftUIBody() {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text(expectRuntimeWarning { self.model.count }.description)
        }
      }
      self.render(FeatureView())
    }

    func testNotInPerceptionBody_InSwiftUIBody_Wrapper() {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Wrapper {
            Text(expectRuntimeWarning { self.model.count }.description)
          }
        }
      }
      self.render(FeatureView())
    }

    func testInPerceptionBody_InSwiftUIBody_Wrapper() {
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
      self.render(FeatureView())
    }

    func testInPerceptionBody_InSwiftUIBody() {
      struct FeatureView: View {
        let model = Model()
        var body: some View {
          WithPerceptionTracking {
            Text(self.model.count.description)
          }
        }
      }
      self.render(FeatureView())
    }

    func testNotInPerceptionBody_SwiftUIBinding() {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Form {
            TextField("", text: expectRuntimeWarning { self.$model.text })
          }
        }
      }
      self.render(FeatureView())
    }

    func testInPerceptionBody_SwiftUIBinding() {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          WithPerceptionTracking {
            TextField("", text: self.$model.text)
          }
        }
      }
      self.render(FeatureView())
    }

    func testNotInPerceptionBody_ForEach() {
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

      self.render(FeatureView())
    }

    func testInnerInPerceptionBody_ForEach() {
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

      self.render(FeatureView())
    }

    func testOuterInPerceptionBody_ForEach() {
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

      self.render(FeatureView())
    }

    func testOuterAndInnerInPerceptionBody_ForEach() {
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

      self.render(FeatureView())
    }

    func testNotInPerceptionBody_Sheet() {
      struct FeatureView: View {
        @State var model = Model(child: Model())
        var body: some View {
          Text("Parent")
            .sheet(item: expectRuntimeWarning { $model.child }) { child in
              Text(expectRuntimeWarning { child.count }.description)
            }
        }
      }

      self.render(FeatureView())
    }

    func testInnerInPerceptionBody_Sheet() {
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

      self.render(FeatureView())
    }

    func testOuterInPerceptionBody_Sheet() {
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

      self.render(FeatureView())
    }

    func testOuterAndInnerInPerceptionBody_Sheet() {
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

      self.render(FeatureView())
    }

    func testActionClosure() {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onAppear { _ = self.model.count }
        }
      }

      self.render(FeatureView())
    }

    func testActionClosure_CallMethodWithArguments() {
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

      self.render(FeatureView())
    }

    func testActionClosure_WithArguments() {
      struct FeatureView: View {
        @State var model = Model()
        var body: some View {
          Text("Hi")
            .onReceive(Just(1)) { _ in
              _ = self.model.count
            }
        }
      }

      self.render(FeatureView())
    }

    func testActionClosure_WithArguments_ImplicitClosure() {
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

      self.render(FeatureView())
    }

    func testImplicitActionClosure() {
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

      self.render(FeatureView())
    }

    func testRegistrarDisablePerceptionTracking() {
      struct FeatureView: View {
        let model = Model()
        let registrar = PerceptionRegistrar(isPerceptionCheckingEnabled: false)
        var body: some View {
          let _ = registrar.access(model, keyPath: \.count)
          Text("Hi")
        }
      }
      self.render(FeatureView())
    }

    func testGlobalDisablePerceptionTracking() {
      let previous = Perception.isPerceptionCheckingEnabled
      Perception.isPerceptionCheckingEnabled = false
      defer { Perception.isPerceptionCheckingEnabled = previous }

      struct FeatureView: View {
        let model = Model()
        var body: some View {
          Text(model.count.description)
        }
      }
      self.render(FeatureView())
    }

    func testParentAccessingChildState_ParentNotObserving_ChildObserving() {
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

      self.render(FeatureView())
    }

    func testParentAccessingChildState_ParentObserving_ChildNotObserving() {
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

      self.render(FeatureView())
    }

    func testParentAccessingChildState_ParentNotObserving_ChildNotObserving() {
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

      self.render(FeatureView())
    }

    func testParentAccessingChildState_ParentObserving_ChildObserving() {
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

      self.render(FeatureView())
    }

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
      self.render(FeatureView())
      try await Task.sleep(for: .milliseconds(100))
    }

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
        func perform() async {
          _ = model.count
        }
      }
      self.render(FeatureView())
      try await Task.sleep(for: .milliseconds(100))
    }

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
      self.render(FeatureView())
      try await Task.sleep(for: .milliseconds(100))
    }

    func testGeometryReader_WithoutPerceptionTracking() {
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
      self.render(FeatureView())
    }

    func testGeometryReader_WithProperPerceptionTracking() {
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
      self.render(FeatureView())
    }

    func testGeometryReader_ComputedProperty_ImproperPerceptionTracking() {
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
      self.render(FeatureView())
    }

    func testOnChange() {
      struct FeatureView: View {
        let model = Model()
        @State var count = 0
        var body: some View {
          Text("Hi")
            .onChange(of: count) { _ in
              _ = model.count
            }
            .onAppear { count += 1 }
        }
      }
      self.render(FeatureView())
    }

    private func render(_ view: some View) {
      let image = ImageRenderer(content: view).cgImage
      _ = image
    }
  }

  private func expectRuntimeWarning<R>(failingBlock: () -> R) -> R {
    XCTExpectFailure(failingBlock: failingBlock) {
      $0.compactDescription == """
        Perceptible state was accessed but is not being tracked. Track changes to state by \
        wrapping your view in a 'WithPerceptionTracking' view.
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
