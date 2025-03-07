#if canImport(SwiftUI)
import Perception
import SwiftUI
import Testing

struct WithPerceptionTrackingDSLTests {
  @Test
  @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
  func buildsAccessibilityRotorContent() {
    _ = WithPerceptionTracking {
      AccessibilityRotorEntry("foo", id: "bar")
    }
  }

  @Test
  @available(iOS 14, macOS 11, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func buildsCommandContent() {
    _ = WithPerceptionTracking {
      EmptyCommands()
    }
  }

  @Test
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func buildsCustomizableToolbarContent() {
    _ = WithPerceptionTracking {
      ToolbarItem {
        EmptyView()
      }
    }
  }

  @Test
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func buildsScene() {
    _ = WithPerceptionTracking {
      WindowGroup {
        EmptyView()
      }
    }
  }

  @Test
  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func buildsTableColumnContent() {
    _ = WithPerceptionTracking {
      TableColumn("Foo", value: \IdentifiableMock.id)
    }
  }

  @Test
  @available(iOS 16, macOS 12, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func buildsTableRowContent() {
    _ = WithPerceptionTracking {
      TableRow(IdentifiableMock(id: ""))
    }
  }

  @Test
  @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
  func buildsToolbarContent() {
    _ = WithPerceptionTracking {
      ToolbarItemGroup {
        EmptyView()
      }
    }
  }

  @Test
  func buildsSwiftUIView() {
    _ = WithPerceptionTracking {
      EmptyView()
    }
  }

  @Test
  func buildsCustomDSL() {
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
