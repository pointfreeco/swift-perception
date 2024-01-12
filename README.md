# Perception

[![CI](https://github.com/pointfreeco/swift-perception/workflows/CI/badge.svg)](https://github.com/pointfreeco/swift-perception/actions?query=workflow%3ACI)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-perception%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-perception)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-perception%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-perception)

Observation tools for platforms that do not officially support observation.

## Learn More

This library was created by [Brandon Williams][mbrandonw] and [Stephen Celis][stephencelis], who
host the [Point-Free][pointfreeco] video series which explores advanced Swift language concepts.

<a href="https://www.pointfree.co/">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0252.jpeg" width="600">
</a>

## Overview

The Perception library provides tools that mimic `@Observable` and `withObservationTracking` in
Swift 5.9, but they are backported to work all the way back to iOS 13, macOS 10.15, tvOS 13 and
watchOS 6. This means you can start taking advantage of Swift 5.9's observation tools today,
even if you can't drop support for older Apple platforms. Using this library's tools works almost
exactly as using the official tools, but with one small exception.

To begin, mark a class as being observable by using the `@Perceptible` macro instead of the
`@Observable` macro:

```swift
@Perceptible
class FeatureModel {
  var count = 0
}
```

Then you can hold onto a perceptible model in your view using a regular `let` property:

```swift
struct FeatureView: View {
  let model: FeatureModel

  // ...
}
```

And in the view's `body` you must wrap your content using the `WithPerceptionTracking` view in
order for observation to be correctly hooked up:

```swift
struct FeatureView: View {
  let model: FeatureModel

  var body: some View {
    WithPerceptionTracking {
      Form {
        Text(model.count.description)
        Button("Increment") { model.count += 1 }
      }
    }
  }
}
```

It's unfortunate to have to wrap your view's content in `WithPerceptionTracking`, however if you
forget then you will helpfully get a runtime warning letting you know that observation is not
set up correctly:

> 🟣 Runtime Warning: Perceptible state was accessed but is not being tracked. Track changes to
> state by wrapping your view in a 'WithPerceptionTracking' view.

### Bindable

SwiftUI's `@Bindable` property wrapper has also been backported to support perceptible objects. You
can simply qualify the property wrapper with the `Perception` module:

```swift
struct FeatureView: View {
  @Perception.Bindable var model: FeatureModel

  // ...
}
```

### Environment

SwiftUI's `@Environment` property wrapper and `environment` view modifier's support for observation
has also been backported to support perceptible objects using the exact same APIs:

```swift
struct FeatureView: View {
  @Environment(Settings.self) var settings

  // ...
}

// In some parent view:
.environment(settings)
```

## Community

If you want to discuss this library or have a question about how to use it to solve
a particular problem, there are a number of places you can discuss with fellow
[Point-Free](https://www.pointfree.co) enthusiasts:

* For long-form discussions, we recommend the
[discussions](https://github.com/pointfreeco/swift-perception/discussions) tab of this repo.
* For casual chat, we recommend the [Point-Free Community Slack](https://pointfree.co/slack-invite).

## Documentation

The latest documentation for the Perception APIs is available [here][docs].

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[pointfreeco]: https://www.pointfree.co
[mbrandonw]: https://twitter.com/mbrandonw
[stephencelis]: https://twitter.com/stephencelis
[docs]: https://swiftpackageindex.com/pointfreeco/swift-perception/main/documentation/perception
