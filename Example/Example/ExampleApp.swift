import SwiftUI
import Perception

@main
struct ExampleApp: App {
  let model = CounterModel()

  var body: some Scene {
    WithPerceptionTracking {
      let _ = print("!!!")
//      let _ = model.count
      WindowGroup {
        ContentView(model: model)
      }
    }
  }
}
