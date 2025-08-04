import Perception
import XCTest

final class PerceptionTrackingTests: XCTestCase {
  var isComplete = false

  func testMutateAccessedField() {
    let model = Model()

    let expectation = self.expectation(description: "count1 changed")
    withPerceptionTracking {
      _ = model.count1
    } onChange: { [weak self] in
      guard let self else { return }
      if !self.isComplete {
        expectation.fulfill()
      }
    }
    model.count1 += 1
    XCTAssertEqual(model.count1, 1)
    XCTAssertEqual(model.count2, 0)
    self.wait(for: [expectation], timeout: 0)
    isComplete = true
  }

  func testMutateNonAccessedField() {
    let model = Model()
    withPerceptionTracking {
      _ = model.count1
    } onChange: { [weak self] in
      guard let self else { return }
      if !self.isComplete {
        XCTFail("count1 should not have changed.")
      }
    }
    model.count2 += 1
    XCTAssertEqual(model.count1, 0)
    XCTAssertEqual(model.count2, 1)
    isComplete = true
  }

  func testMutateSpecificAccessedField() {
    let model = Model()

    let expectation = self.expectation(description: "count1 changed")
    withPerceptionTracking {
      _ = model.count1
      _ = model.count2
    } for: \.count1 onChange: { [weak self] in
      guard let self else { return }
      if !self.isComplete {
        expectation.fulfill()
      }
    }
    model.count2 += 1
    XCTAssertEqual(model.count1, 0)
    XCTAssertEqual(model.count2, 1)
    self.wait(for: [expectation], timeout: 0.001) // Should not fulfill

    model.count1 += 1
    XCTAssertEqual(model.count1, 1)
    XCTAssertEqual(model.count2, 1)
    self.wait(for: [expectation], timeout: 0)
    isComplete = true
  }
}

@Perceptible
private class Model {
  var count1 = 0
  var count2 = 0
}
