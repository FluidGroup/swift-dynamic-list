import IndexedCollection
import SwiftUI

public enum VersatileListDirection {
  case vertical
  case horizontal
}

public enum CollectionViewLayout {

  case list
  case grid

  public struct List<Separator: View> {
    
  }

  public struct Grid {

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
  Separator: View
>: View where Data.Element: Identifiable {

  public let direction: VersatileListDirection

  private let cell: (Data.Element) -> Cell
  private let separator: () -> Separator
  private let items: Data

  public init(
    items: Data,
    direction: VersatileListDirection,
    @ViewBuilder cell: @escaping (Data.Element) -> Cell,
    @ViewBuilder separator: @escaping () -> Separator
  ) {

    self.direction = direction
    self.cell = cell
    self.separator = separator
    self.items = items
  }

  public var body: some View {

    // for now, switching verbose way

    switch direction {
    case .vertical:

      ScrollView(.vertical) {
        LazyVStack {
          ForEach(IndexedCollection(items)) { element in
            cell(element.value)
          }
        }
      }

    case .horizontal:

      ScrollView(.horizontal) {
        LazyHStack {
          ForEach(IndexedCollection(items)) { element in
            cell(element.value)
          }
        }
      }

    }

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

  #Preview {

    CollectionView(
      items: Item.mock(), direction: .vertical,
      cell: { item in
        Text(item.title)
      }, 
      separator: { EmptyView() }
    )
  }

#endif
