# swift-dynamic-list
Convenient component displaying elements in UICollectionView - Supports SwiftUI-based cell

## Instructions

> Works in UIKit

```swift
let list = DynamicListView<Section, Element>.init(...)
```

Setting how displays cells
    
```swift
list.setUp(
  cellProvider: { context in
    let data = context.data
    // return cell
  }
)
```

the context in cellProvider closure supports making SwiftUI based cells.

```swift
let cell = context.cell { state in
  Text("Hello")
}
return cell
```
