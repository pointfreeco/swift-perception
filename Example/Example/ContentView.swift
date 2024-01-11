import Perception
import SwiftUI

@Perceptible
class CounterModel {
  var count = 0
  var isDisplayingCount = true
  var isPresentingSheet = false
  func decrementButtonTapped() {
    count -= 1
  }
  func incrementButtonTapped() {
    count += 1
  }
  func presentSheetButtonTapped() {
    isPresentingSheet = true
  }
}

struct ContentView: View {
  @PerceptibleObject var model: CounterModel

  var body: some View {
    @Perception.Bindable var model = model

    WithPerceptionTracking {
      let _ = print("\(Self.self): tracked change.")
      Form {
        if model.isDisplayingCount {
          Text(model.count.description)
        } else {
          Text("Not tracking count")
        }
        Button("Decrement") { model.decrementButtonTapped() }
        Button("Increment") { model.incrementButtonTapped() }
        Toggle(isOn: $model.isDisplayingCount) {
          Text("Display count?")
        }
        Button("Present sheet") {
          model.presentSheetButtonTapped()
        }
      }
      .sheet(isPresented: $model.isPresentingSheet) {
        WithPerceptionTracking {
          Form {
            Text(model.count.description)
            Button("Decrement") { model.decrementButtonTapped() }
            Button("Increment") { model.incrementButtonTapped() }
          }
        }
        .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  ContentView()
    .perceptibleObject(CounterModel())
}
