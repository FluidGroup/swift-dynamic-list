
#if DEBUG

import SwiftUI

struct Item: Identifiable {
  var id: Int
  var title: String
  
  static func mock(_ count: Int = 1000) -> [Item] {
    return (0..<count).map { index in
      Item(id: index, title: "Item \(index)")
    }
  }
}

struct Cell: View {
  
  @Environment(\.isEnabled) var isEnabled
  @Environment(\.collectionView_isSelected) var isSelected
  @Environment(\.collectionView_updateSelection) var updateSelection
  
  let index: Int
  let item: Item
  
  init(index: Int, item: Item) {
    
    print("Cell init \(index), \(item.title)")
    
    self.index = index
    self.item = item
  }
  
  var body: some View {
    HStack {
      Circle()
        .fill(.red)
        .frame(width: 20, height: 20)
        .opacity(isSelected ? 1 : 0.2)
      Text(index.description)
      Text(item.title)
      Text("isEnabled: \(isEnabled)")
    }
    ._onButtonGesture(
      pressing: { _ in },
      perform: {
        updateSelection(!isSelected)
      })
  }
}
#endif