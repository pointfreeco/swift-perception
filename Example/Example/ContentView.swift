import Perception
import SwiftUI

@Perceptible
class CounterModel {
  var count: Int {
    @storageRestrictions(initializes: _count)
    init(initialValue) {
      _count = initialValue
    }
    get {
      print(Thread.callStackSymbols.dropFirst().first)
      _$perceptionRegistrar.access(self, keyPath: \.count)
      return _count
    }
    set {
      guard shouldNotifyObservers(_count, newValue) else {
        _count = newValue
        return
      }
      withMutation(keyPath: \.count) {
        _count = newValue
      }
    }
    _modify {
      print(Thread.callStackSymbols.dropFirst().first)
      access(keyPath: \.count)
      _$perceptionRegistrar.willSet(self, keyPath: \.count)
      defer {
        _$perceptionRegistrar.didSet(self, keyPath: \.count)
      }
      yield &_count
    }
  }
  @PerceptionIgnored private var _count = 0

  @PerceptionTracked var isDisplayingCount = true
  @PerceptionTracked var isPresentingSheet = false
  @PerceptionTracked var text = ""
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

extension CounterModel: Perception.Perceptible, Observation.Observable {
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
