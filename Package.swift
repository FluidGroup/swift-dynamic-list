// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-dynamic-list",
  platforms: [.iOS(.v14)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "swift-dynamic-list",
      targets: ["swift-dynamic-list"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/FluidGroup/swiftui-hosting", from: "1.1.0"),
    .package(url: "https://github.com/FluidGroup/swiftui-support", from: "0.4.1"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "swift-dynamic-list",
      dependencies: [
        .product(name: "SwiftUIHosting", package: "swiftui-hosting"),
        .product(name: "SwiftUISupport", package: "swiftui-support")
      ]
    ),
    .testTarget(
      name: "swift-dynamic-listTests",
      dependencies: ["swift-dynamic-list"]
    ),
  ]
)
