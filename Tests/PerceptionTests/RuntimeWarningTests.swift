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
    self.expectFailure()

    struct FeatureView: View {
      let model = Model()
      var body: some View {
        Text(self.model.count.description)
      }
    }
    self.render(FeatureView())
  }

  func testNotInPerceptionBody_InSwiftUIBody_Wrapper() {
    self.expectFailure()

    struct FeatureView: View {
      let model = Model()
      var body: some View {
        Wrapper {
          Text(self.model.count.description)
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
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model()
      var body: some View {
        VStack {
          TextField("", text: self.$model.text)
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
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model(
        list: [
          Model(count: 1),
          Model(count: 2),
          Model(count: 3),
        ]
      )
      var body: some View {
        ForEach(model.list) { model in
          Text(model.count.description)
        }
      }
    }

    self.render(FeatureView())
  }

  func testInnerInPerceptionBody_ForEach() {
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model(
        list: [
          Model(count: 1),
          Model(count: 2),
          Model(count: 3),
        ]
      )
      var body: some View {
        ForEach(model.list) { model in
          WithPerceptionTracking {
            Text(model.count.description)
          }
        }
      }
    }

    self.render(FeatureView())
  }

  func testOuterInPerceptionBody_ForEach() {
    self.expectFailure()

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
            Text(model.count.description)
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
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model(child: Model())
      var body: some View {
        Text("Parent")
          .sheet(item: $model.child) { child in
            Text(child.count.description)
          }
      }
    }

    self.render(FeatureView())
  }

  func testInnerInPerceptionBody_Sheet() {
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model(child: Model())
      var body: some View {
        Text("Parent")
          .sheet(item: $model.child) { child in
            WithPerceptionTracking {
              Text(child.count.description)
            }
          }
      }
    }

    self.render(FeatureView())
  }

  func testOuterInPerceptionBody_Sheet() {
    self.expectFailure()

    struct FeatureView: View {
      @State var model = Model(child: Model())
      var body: some View {
        WithPerceptionTracking {
          Text("Parent")
            .sheet(item: $model.child) { child in
              Text(child.count.description)
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
    self.expectFailure()

    struct ChildView: View {
      let model: Model
      var body: some View {
        WithPerceptionTracking {
          Text(model.count.description)
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
        ChildView(model: self.childModel)
        Text(childModel.count.description)
      }
    }

    self.render(FeatureView())
  }

  func testParentAccessingChildState_ParentObserving_ChildNotObserving() {
    self.expectFailure()

    struct ChildView: View {
      let model: Model
      var body: some View {
        Text(model.count.description)
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
      }
    }

    self.render(FeatureView())
  }

  func testParentAccessingChildState_ParentNotObserving_ChildNotObserving() {
    self.expectFailure()

    struct ChildView: View {
      let model: Model
      var body: some View {
        Text(model.count.description)
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
        ChildView(model: self.childModel)
        Text(childModel.count.description)
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
      }
    }

    self.render(FeatureView())
  }

  private func expectFailure() {
    XCTExpectFailure {
      $0.compactDescription == """
        Perceptible state was accessed but is not being tracked. Track changes to state by \
        wrapping your view in a 'WithPerceptionTracking' view.
        """
    }
  }

  private func render(_ view: some View) {
    let image = ImageRenderer(content: view).cgImage
    _ = image
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
