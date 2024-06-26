import Perception
import XCTest

final class ModifyTests: XCTestCase {
  func testCOW() {
    let subject = CowTest()
    let startId = subject.container.id
    XCTAssertEqual(subject.container.id, startId)
    subject.container.mutate()
    XCTAssertEqual(subject.container.id, startId)
  }
}

struct CowContainer {
  final class Contents { }
  var contents = Contents()
  mutating func mutate() {
    if !isKnownUniquelyReferenced(&contents) {
      contents = Contents()
    }
  }
  var id: ObjectIdentifier {
    ObjectIdentifier(contents)
  }
}

@Perceptible
final class CowTest {
  var container = CowContainer()
}
