import SwiftUI
import Perception

@main
struct ExampleApp: App {
  var body: some Scene {
    WithPerceptionTracking {
      WindowGroup {
        ContentView(model: CounterModel())
      }
    }
  }
}
