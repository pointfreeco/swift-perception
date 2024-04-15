import Perception
import SwiftUI

@Perceptible
class CounterModel {
  var count = 0
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
    WithPerceptionTracking {
      let _ = print("\(Self.self): tracked change.")
      Form {
        TextField("Text", text: $model.text)
        if model.isDisplayingCount {
          Text(model.count.description)
            .font(.largeTitle)
        } else {
          Text("Not tracking count")
            .font(.largeTitle)
        }
        Button("Decrement") { model.decrementButtonTapped() }
        Button("Increment") { model.incrementButtonTapped() }
        Toggle(isOn: $model.isDisplayingCount.animation()) {
          Text("Display count?")
        }
        Button("Present sheet") {
          model.presentSheetButtonTapped()
        }
      }
      .sheet(isPresented: $model.isPresentingSheet) {
        if #available(iOS 16.0, *) {
          WithPerceptionTracking {
            Form {
              Text(model.count.description)
                .font(.largeTitle)
              Button("Decrement") { model.decrementButtonTapped() }
              Button("Increment") { model.incrementButtonTapped() }
            }
            .presentationDetents([.medium])
          }
        } else {
          WithPerceptionTracking {
            Form {
              Text(model.count.description)
              Button("Decrement") { model.decrementButtonTapped() }
              Button("Increment") { model.incrementButtonTapped() }
            }
          }
        }
      }
    }
  }
}

#Preview {
  ContentView(model: CounterModel())
}
