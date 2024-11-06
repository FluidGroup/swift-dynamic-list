import IndexedCollection
import SwiftUI

/// Still searching better name
/// - built on top of SwiftUI only
@available(iOS 16, *)
public struct CollectionView<
  Data: RandomAccessCollection,
  Cell: View,
  Layout: CollectionViewLayoutType,
  Selection: CollectionViewSelection<Data.Element>
>: View where Data.Element: Identifiable {

  private let cell: (Data.Index, Data.Element) -> Cell
  private let layout: Layout
  private let items: Data
    
  private var selection: Selection
    
  public init(
    items: Data,
    layout: Layout,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) where Selection == CollectionViewSelectionModes.None<Data.Element> {
    self.cell = cell
    self.layout = layout
    self.items = items
    self.selection = .init()
  }
  
  public init(
    items: Data,
    layout: Layout,
    selection: Selection,
    @ViewBuilder cell: @escaping (Data.Index, Data.Element) -> Cell
  ) {
    self.cell = cell
    self.layout = layout
    self.items = items
    self.selection = selection
  }
  
  public var body: some View {
    
    // for now, switching verbose way
    
    ForEach(IndexedCollection(items)) { element in  
      
      let isSelected: Bool = selection.isSelected(for: element.id)
      let isDisabled: Bool = !selection.isEnabled(for: element.id)
            
      cell(element.index, element.value)
        .disabled(isDisabled)
        .environment(\.collectionView_isSelected, isSelected)
        .environment(\.collectionView_updateSelection, { [selection] isSelected in           
          selection.update(isSelected: isSelected, for: element.value)
        })
    }
    .modifier(layout)
            
  }
  
  public consuming func selection<NewSelection: CollectionViewSelection<Data.Element>>(
    _ selection: NewSelection
  ) -> CollectionView<Data, Cell, Layout, NewSelection> {        
    return .init(items: items, layout: layout, selection: selection, cell: cell)
  }
  
}

extension EnvironmentValues {
  @Entry public var collectionView_isSelected: Bool = false
}

extension EnvironmentValues {
  @Entry public var collectionView_updateSelection: (Bool) -> Void = { _ in }
}

#if DEBUG

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
        canMoreSelect: selected.count < 3,
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
