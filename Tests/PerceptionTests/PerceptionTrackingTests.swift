import Perception
import XCTest

final class PerceptionTrackingTests: XCTestCase {
  func testMutateAccessedField() {
    let model = Model()

    let expectation = self.expectation(description: "count1 changed")
    withPerceptionTracking {
      _ = model.count1
    } onChange: {
      expectation.fulfill()
    }
    model.count1 += 1
    XCTAssertEqual(model.count1, 1)
    XCTAssertEqual(model.count2, 0)
    self.wait(for: [expectation], timeout: 0)
  }
  
  func testMutateNonAccessedField() {
    let model = Model()
    withPerceptionTracking {
      _ = model.count1
    } onChange: {
      XCTFail("count1 should not have changed.")
    }
    model.count2 += 1
    XCTAssertEqual(model.count1, 0)
    XCTAssertEqual(model.count2, 1)
  }
}

@Perceptible
private class Model {
  var count1 = 0
  var count2 = 0
}
