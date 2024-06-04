import SwiftUI
import Perception

@Observable
class Model {
}

struct Foo {
  @Bindable var model = Model()
}
