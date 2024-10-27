import IndexedCollection
import SwiftUI

public enum CollectionViewListDirection {
  case vertical
  case horizontal
}



public protocol CollectionViewLayoutType: ViewModifier {
  
}

public enum CollectionViewLayouts {
  
  public struct PlatformList: CollectionViewLayoutType {
    
    public func body(content: Content) -> some View {
      SwiftUI.List {
        content
      }
    }
  }
  
  public struct List<Separator: View>: CollectionViewLayoutType {
        
    public let direction: CollectionViewListDirection
    
    public init(direction: CollectionViewListDirection) {
      self.direction = direction
    }
           
    public func body(content: Content) -> some View {
      switch direction {
      case .vertical:
        
        ScrollView(.vertical) {
          LazyVStack {
            VariadicViewReader(readingContent: content) { child in
              child
            }
          }
        }
        
      case .horizontal:
        
        ScrollView(.horizontal) {
          LazyHStack {
            VariadicViewReader(readingContent: content) { child in
              child
            }
          }
        }
        
      }
    }
       
  }
  
  public struct Grid: CollectionViewLayoutType {
    
    public func body(content: Content) -> some View {
      
    }
  }
  
}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.List<EmptyView> {
  
  public static var list: Self {
    CollectionViewLayouts.List(direction: .vertical)
  }
  
}

extension CollectionViewLayoutType {
  
  public static func list<Separator: View>(
    @ViewBuilder separator: () -> Separator
  ) -> Self where Self == CollectionViewLayouts.List<Separator> {
    .init(direction: .vertical)
  }
  
}


extension CollectionViewLayoutType where Self == CollectionViewLayouts.Grid {
  
  public static var grid: Self {
    CollectionViewLayouts.Grid()
  }
  
}

public enum SelectionMode {
  case single
  case multiple
}

/// Still searching better name
/// - built on top of SwiftUI only
@available(iOS 16, *)
public struct CollectionView<
  Data: RandomAccessCollection,
  Cell: View,
  Layout: CollectionViewLayoutType
>: View where Data.Element: Identifiable {
  
  public let direction: CollectionViewListDirection
  
  private let cell: (Data.Index, Data.Element) -> Cell
  private let layout: Layout
  private let items: Data
  
  public init(
    items: Data,
    direction: CollectionViewListDirection,
    layout: Layout,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) {
    
    self.direction = direction
    self.cell = cell
    self.layout = layout
    self.items = items
  }
  
  public var body: some View {
    
    // for now, switching verbose way
    
    ForEach(IndexedCollection(items)) { element in      
      cell(element.index, element.value)
    }
    .modifier(layout)
            
  }
}

#if DEBUG

private struct Item: Identifiable {
  var id: Int
  var title: String
  
  static func mock() -> [Item] {
    return (0..<10).map { index in
      Item(id: index, title: "Item \(index)")
    }
  }
}

#Preview("Custom List") {
  
  CollectionView(
    items: Item.mock(), direction: .vertical,
    layout: .list,
    cell: { index, item in
      HStack {
        Text(index.description)
        Text(item.title)
      }
    }
  )
}

#Preview("SwiftUI List") {
  
  CollectionView(
    items: Item.mock(), direction: .vertical,
    layout: CollectionViewLayouts.PlatformList(),
    cell: { index, item in
      HStack {
        Text(index.description)
        Text(item.title)
      }
    }
  )
}

#endif
