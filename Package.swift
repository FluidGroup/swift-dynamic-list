// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-dynamic-list",
  platforms: [.iOS(.v16)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "DynamicList",
      targets: ["DynamicList"]
    ),
    .library(
      name: "CollectionView",
      targets: ["CollectionView"]
    ),
    .library(
      name: "ScrollTracking",
      targets: ["ScrollTracking"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/FluidGroup/swift-indexed-collection", from: "0.2.1"),
    .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.3.0"),
    .package(url: "https://github.com/FluidGroup/swift-with-prerender", from: "1.0.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DynamicList",
      dependencies: [
      ]
    ),
    .target(
      name: "CollectionView",
      dependencies: [
        "ScrollTracking",
        .product(name: "IndexedCollection", package: "swift-indexed-collection"),        
      ]
    ),
    .target(
      name: "ScrollTracking",
      dependencies: [
        .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
        .product(name: "WithPrerender", package: "swift-with-prerender"),
      ]
    ),
    .testTarget(
      name: "DynamicListTests",
      dependencies: ["DynamicList"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
