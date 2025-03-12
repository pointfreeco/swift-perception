#if canImport(SwiftUI)
import Perception
import SwiftUI
import XCTest

final class WithPerceptionTrackingDSLTests: XCTestCase {

  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  func testBuildsAccessibilityRotorContent() {
    _ = WithPerceptionTracking {
      AccessibilityRotorEntry("foo", id: "bar")
    }
  }

  @available(iOS 14, macOS 11, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func testBuildsCommandContent() {
    _ = WithPerceptionTracking {
      EmptyCommands()
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func testBuildsCustomizableToolbarContent() {
    _ = WithPerceptionTracking {
      ToolbarItem {
        EmptyView()
      }
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func testBuildsScene() {
    _ = WithPerceptionTracking {
      WindowGroup {
        EmptyView()
      }
    }
  }

  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func testBuildsTableColumnContent() {
    _ = WithPerceptionTracking {
      TableColumn("Foo", value: \IdentifiableMock.id)
    }
  }

  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func testBuildsTableRowContent() {
    _ = WithPerceptionTracking {
      TableRow(IdentifiableMock(id: ""))
    }
  }

  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func testBuildsToolbarContent() {
    _ = WithPerceptionTracking {
      ToolbarItemGroup {
        EmptyView()
      }
    }
  }

  func testBuildsSwiftUIView() {
    _ = WithPerceptionTracking {
      EmptyView()
    }
  }

  func testBuildsCustomDSL() {
    _ = WithPerceptionTracking {
      CustomDSL()
    }
  }

}

private struct IdentifiableMock: Identifiable {
  var id: String
}

private protocol CustomDSLContent {}
private struct CustomDSL: CustomDSLContent {}

@resultBuilder
private struct CustomDSLContentBuilder {
    /// Builds an expression within the map content builder.
    public static func buildBlock<Content>(_ content: Content) -> Content where Content: CustomDSLContent {
        content
    }
}

extension WithPerceptionTracking: CustomDSLContent where Content: CustomDSLContent {
  init(@CustomDSLContentBuilder content: @escaping () -> Content) {
    self.init(content: content())
  }
}

#endif
