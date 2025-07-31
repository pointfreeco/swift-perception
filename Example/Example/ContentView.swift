import Perception
import SwiftUI

@Perceptible
class CounterModel {
  var count: Int = 0
  var isDisplayingCount = true
  var isPresentingSheet = false
  var text = ""



  func decrementButtonTapped() {
    withAnimation {
      count -= 1
    }
  }
  func incrementButtonTapped() {
    withAnimation {
      count += 1
    }
  }
  func presentSheetButtonTapped() {
    isPresentingSheet = true
  }
}

struct ContentView: View {
  @Perception.Bindable var model: CounterModel

  var body: some View {
    Form {
      WithPerceptionTracking {
        Text(model.count.description)
          .font(.largeTitle)
        Button("Decrement") { model.decrementButtonTapped() }
        Button("Increment") { model.incrementButtonTapped() }
      }
      Text(model.count.description)
        .font(.largeTitle)
    }
  }
}

#Preview {
  ContentView(model: CounterModel())
}
