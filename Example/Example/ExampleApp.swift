import SwiftUI

@main
struct ExampleApp: App {
  static let model = CounterModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .perceptibleObject(ExampleApp.model)
    }
  }
}
