import SwiftUI

#if DEBUG

struct Item: Identifiable {
  var id: Int
  var title: String
  
  static func mock() -> [Item] {
    return (0..<1000).map { index in
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
    ._onButtonGesture(pressing: { _ in }, perform: {
      updateSelection(!isSelected)
    })
  }
}

private struct ConfirmingSingle<Item: Identifiable>: CollectionViewSelection {
  
  private let selected: Item.ID?
  private let onChange: (_ selected: Item?) -> Void
  private let canSelect: (_ item: Item) -> Bool
  
  public init(
    selected: Item.ID?,
    canSelect: @escaping (_ item: Item) -> Bool,
    onChange: @escaping (_ selected: Item?) -> Void      
  ) {
    self.selected = selected
    self.onChange = onChange
    self.canSelect = canSelect
  }
  
  public func isSelected(for id: Item.ID) -> Bool {
    self.selected == id
  }
  
  public func isEnabled(for id: Item.ID) -> Bool {
    return true
  }
  
  public func update(isSelected: Bool, for item: Item) {    
    if isSelected {
      if canSelect(item) {
        onChange(item)
      }
    } else {
      onChange(nil)
    }
  }
  
}

#Preview("Custom List / Single selection") {
  
  struct Book: View {
    
    @State var selected: Item?
    @State var isAlertPresented = false
    
    var body: some View {
      CollectionView(
        items: Item.mock(),
        layout: .list {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 8)
            .padding(.horizontal, 20)      
        },
        cell: { index, item in
          Cell(index: index, item: item)
        }
      )
      .selection(
        ConfirmingSingle(
          selected: selected?.id,
          canSelect: { item in 
            if item.title.contains("Item 1") {
              self.isAlertPresented = true
              return false            
            } else {
              return true
            }
          },
          onChange: { selected in
            self.selected = selected
          })
      )
      .alert("Can not select", isPresented: $isAlertPresented, actions: {
        
      })
    }
  }
  
  return Book()
}

#endif
