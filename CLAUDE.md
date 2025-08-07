# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the Swift package
swift build

# Build the development app (for testing features)
xcodebuild -project Development/Development.xcodeproj -scheme Development build
```

## Test Commands

```bash
# Run all tests
swift test

# Run tests using Xcode
xcodebuild test -project Development/Development.xcodeproj -scheme Development
```

## Architecture Overview

This is a Swift Package providing UIKit-based collection view components with SwiftUI integration, organized into four main modules:

### DynamicList (Main module)
- **DynamicListView**: Core UIKit-based collection view with NSDiffableDataSource
- **VersatileCell**: Flexible cell implementation supporting SwiftUI content via hosting
- **HostingConfiguration**: Manages SwiftUI view hosting in UIKit cells
- Supports incremental content loading with `ContentPagingTrigger`

### CollectionView
- **CollectionView**: Pure SwiftUI implementation using UICollectionView under the hood
- **SelectableForEach**: Provides selection support (single/multiple)
- **CollectionViewLayout**: Configurable layouts (list, grid, compositional)

### ScrollTracking
- Provides scroll position tracking functionality for SwiftUI views

### StickyHeader
- Implements sticky header behavior for scroll views

## Key Implementation Patterns

### Cell Provider Pattern
The library uses a cell provider pattern where cells are configured through closures:

```swift
list.setUp(
  cellProvider: { context in
    // context.cell returns a UICollectionViewCell hosting SwiftUI content
    context.cell { state in
      // SwiftUI view content
    }
  }
)
```

### Diffable Data Source
Uses NSDiffableDataSourceSnapshot for efficient updates with custom extensions for safety:
- `NSDiffableDataSourceSnapshot+Unique.swift` provides safe operations

### SwiftUI Integration
- UIKit cells host SwiftUI views through `HostingConfiguration`
- Supports state preservation and updates
- Pre-rendering capabilities via swift-with-prerender dependency

## Platform Requirements
- iOS 16+
- macOS 15+
- Swift 6.0 language mode

## Development App
The Development/ directory contains a comprehensive example app demonstrating:
- Various collection view layouts
- Selection handling
- Performance testing
- Different implementation approaches