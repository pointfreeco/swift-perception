// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-perception",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "PerceptionCore",
      targets: ["PerceptionCore"]
    ),
    .library(
      name: "Perception",
      targets: ["Perception"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.6.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
  ],
  targets: [
    .target(
      name: "Perception",
      dependencies: [
        "PerceptionCore",
        "PerceptionMacros",
      ]
    ),
    .target(
      name: "PerceptionCore",
      dependencies: [
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
      ]
    ),
    .macro(
      name: "PerceptionMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "PerceptionTests",
      dependencies: ["Perception"]
    ),
    .testTarget(
      name: "PerceptionMacrosTests",
      dependencies: [
        "PerceptionMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
