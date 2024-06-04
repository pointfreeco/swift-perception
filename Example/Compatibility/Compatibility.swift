import Perception
import SwiftUI

@Observable class Model {}

func testUnqualifiedBindable() {
  @Bindable var model = Model()
}
