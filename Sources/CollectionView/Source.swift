import IndexedCollection
import SwiftUI

public enum CollectionViewListDirection {
  case vertical
  case horizontal
}

/**
 A protocol that makes laid out contents of the collection view
 */
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
    public let contentPadding: EdgeInsets

    private let separator: Separator
    
    public init(
      direction: CollectionViewListDirection,
      contentPadding: EdgeInsets = .init(),
      @ViewBuilder separator: () -> Separator
    ) {
      self.direction = direction
      self.contentPadding = contentPadding
      self.separator = separator()
    }
           
    public func body(content: Content) -> some View {
      switch direction {
      case .vertical:
        
        ScrollView(.vertical) {
          LazyVStack {
            VariadicViewReader(readingContent: content) { children in
              let last = children.last?.id
              ForEach(children) { child in 
                child
                if child.id != last {
                  separator
                }
              }              
            }
          }
          .padding(contentPadding)
        }
        
      case .horizontal:
        
        ScrollView(.horizontal) {
          LazyHStack {
            VariadicViewReader(readingContent: content) { children in
              let last = children.last?.id
              ForEach(children) { child in 
                child
                if child.id != last {
                  separator
                }
              }  
            }
          }
          .padding(contentPadding)
        }
        
      }
    }
       
  }
  
  public struct Grid: CollectionViewLayoutType {
    
    public func body(content: Content) -> some View {
      // FIXME:
    }
  }
  
}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.List<EmptyView> {
  
  public static var list: Self {
    CollectionViewLayouts.List(
      direction: .vertical,
      separator: { EmptyView() }
    )
  }
  
}

extension CollectionViewLayoutType {
  
  public static func list<Separator: View>(
    @ViewBuilder separator: () -> Separator
  ) -> Self where Self == CollectionViewLayouts.List<Separator> {
    .init(direction: .vertical, separator: separator)
  }
  
}


extension CollectionViewLayoutType where Self == CollectionViewLayouts.Grid {
  
  public static var grid: Self {
    CollectionViewLayouts.Grid()
  }
  
}

public enum SelectAction {
  case selected
  case deselected
}

/// 
public enum Selection<Item: Identifiable> {
  
  /**
   Single selection
   
   - Parameters:
   - selected:
   - onChange: passing newly selected item, nil represents as deselected.
   */
  case single(
    selected: Item.ID?,
    onChange: (_ selected: Item?) -> Void)
  
  /**
   Multiple selection
   
   - Parameters:
     - selected:
     - onChange: passing newly selected item, nil represents as deselected.
   */
  case multiple(
    selected: Set<Item.ID>,
    onChange: (_ selected: Item, _ action: SelectAction) -> Void
  )
}

/// Still searching better name
/// - built on top of SwiftUI only
@available(iOS 16, *)
public struct CollectionView<
  Data: RandomAccessCollection,
  Cell: View,
  Layout: CollectionViewLayoutType
>: View where Data.Element: Identifiable {

  private let cell: (Data.Index, Data.Element) -> Cell
  private let layout: Layout
  private let items: Data
    
  private var selection: Selection<Data.Element>?
    
  public init(
    items: Data,
    layout: Layout,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) {
    self.cell = cell
    self.layout = layout
    self.items = items
  }
  
  public var body: some View {
    
    // for now, switching verbose way
    
    ForEach(IndexedCollection(items)) { element in  
      
      let isSelected = {
        switch selection {
        case .none: 
          return false
        case .single(let id, _):
          return element.id == id
        case .multiple(let set, _):
          return set.contains(element.id)
        }
      }()
      
      cell(element.index, element.value)
        .environment(\.collectionView_isSelected, isSelected)
        .environment(\.collectionView_updateSelection, { [selection] isSelected in 
          
          switch (selection) {
          case (.single(_, let onChange)):
            if isSelected {
              onChange(element.value)
            } else {
              onChange(nil)
            }
          case .multiple(_, let onChange):
            if isSelected {
              onChange(element.value, .selected)
            } else {
              onChange(element.value, .deselected)
            }
          default:
            break
          }
        })
    }
    .modifier(layout)
            
  }
  
  public consuming func selection(
    _ selection: Selection<Data.Element>
  ) -> Self {    
    
    self.selection = selection
    
    return self
  }
}

extension EnvironmentValues {
  @Entry var collectionView_isSelected: Bool = false
}

extension EnvironmentValues {
  @Entry var collectionView_updateSelection: (Bool) -> Void = { _ in }
}

#if DEBUG

private struct Item: Identifiable {
  var id: Int
  var title: String
  
  static func mock() -> [Item] {
    return (0..<1000).map { index in
      Item(id: index, title: "Item \(index)")
    }
  }
}

private struct Cell: View {
  
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
    }
    ._onButtonGesture(pressing: { _ in }, perform: {
      updateSelection(!isSelected)
    })
  }
}

#Preview("Custom List / Single selection") {
  
  struct Book: View {
    
    @State var selected: Item?
    
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
      .selection(.single(
        selected: selected?.id,
        onChange: { e in
          selected = e
      }))
    }
  }

  return Book()
}

#Preview("Custom List / Multiple selection") {
  
  struct Book: View {
    
    @State var selected: Set<Item.ID> = .init()
    
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
      .selection(.multiple(
        selected: selected,
        onChange: { e, action in
          switch action {
          case .selected:
            selected.insert(e.id)
          case .deselected:
            selected.remove(e.id)
          }
        }))
    }
  }
  
  return Book()
}

#Preview("SwiftUI List") {
  
  CollectionView(
    items: Item.mock(),
    layout: CollectionViewLayouts.PlatformList(),
    cell: { index, item in
      HStack {
        Text(index.description)
        Text(item.title)
      }
    }
  )
}

#Preview {
  
  struct BookList: View {
    
    struct Ocean: Identifiable, Hashable {
      let name: String
      let id = UUID()
    }
    
    
    private var oceans = [
      Ocean(name: "Pacific"),
      Ocean(name: "Atlantic"),
      Ocean(name: "Indian"),
      Ocean(name: "Southern"),
      Ocean(name: "Arctic")
    ]
    
    
    @State private var multiSelection = Set<UUID>()
        
    var body: some View {
      NavigationView {
        List(oceans, selection: $multiSelection) {
          Text($0.name)
        }
        .navigationTitle("Oceans")
//        .toolbar { EditButton() }
      }
      Text("\(multiSelection.count) selections")
    }
    
  }
  
  return BookList()
}

#endif
