import CollectionView
import SwiftUI

struct BookCollectionViewSingleSection: View, PreviewProvider {

  var body: some View {
    ContentView()
  }

  static var previews: some View {
    Self()
      .previewDisplayName(nil)
  }

  private struct ContentView: View {

    @State var selected: Item?

    var body: some View {
      CollectionView(
        dataSource: .collection(
          data: Item.mock(),
          selection: .single(
            selected: selected?.id,
            onChange: { e in
              selected = e
            }),
          cell: { index, item in
            Cell(index: index, item: item)
          }
        ),
        layout: .list {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 8)
            .padding(.horizontal, 20)
        }
      )
    }
  }

}

struct BookCollectionViewCombined: View, PreviewProvider {

  var body: some View {
    ContentView()
  }

  static var previews: some View {
    Self()
      .previewDisplayName(nil)
  }

  private struct ContentView: View {

    @State var selected: Item?
    @State var selected2: Item?

    var body: some View {
      CollectionView(
        dataSource: CollectionViewDataSources.Unified {

          Text("Static content")
            .overlay(content: {

            })

          Text("📱❄️")

          CollectionViewDataSources.UsingCollection(
            data: Item.mock(10),
            selection: .single(
              selected: selected?.id,
              onChange: { e in
                selected = e
              }),
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )

          Text("📱❄️")

          CollectionViewDataSources.UsingCollection(
            data: Item.mock(10),
            selection: .single(
              selected: selected2?.id,
              onChange: { e in
                selected2 = e
              }),
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )

          Text("📱❄️")

          ForEach(Item.mock(10)) { item in
            Cell(index: item.id, item: item)
          }

        },
        layout: .list {
          EmptyView()
        }
      )
    }
  }

}

#Preview {
  CollectionViewDataSources.UsingCollection(
    data: Item.mock(10),
    selection: .disabled(),
    cell: { index, item in
      Cell(index: index, item: item)
    }
  )  
}
//#Preview {
//  BookPreview()
//}

#Preview("Custom List / Single selection") {

  struct Book: View {

    @State var selected: Item?

    var body: some View {
      CollectionView(
        dataSource: CollectionViewDataSources.UsingCollection(
          data: Item.mock(),
          selection: .single(
            selected: selected?.id,
            onChange: { e in
              selected = e
            }),
          cell: { index, item in
            Cell(index: index, item: item)
          }
        ),
        layout: .list {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 8)
            .padding(.horizontal, 20)
        }
      )
    }
  }

  return Book()
}

#Preview("Custom List / Multiple selection") {

  struct Book: View {

    @State var selected: Set<Item.ID> = .init()

    var body: some View {

      CollectionView(
        dataSource: CollectionViewDataSources.UsingCollection(
          data: Item.mock(),
          selection: .multiple(
            selected: selected,
            canMoreSelect: selected.count < 3,
            onChange: { e, action in
              switch action {
              case .selected:
                selected.insert(e.id)
              case .deselected:
                selected.remove(e.id)
              }
            }),
          cell: { index, item in
            Cell(index: index, item: item)
          }
        ),
        layout: .list {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 8)
            .padding(.horizontal, 20)
        }
      )
    }
  }

  return Book()
}

#Preview("SwiftUI List") {

  CollectionView(
    dataSource: CollectionViewDataSources.UsingCollection(
      data: Item.mock(),
      selection: .disabled(),
      cell: { index, item in
        HStack {
          Text(index.description)
          Text(item.title)
        }
      }
    ),
    layout: CollectionViewLayouts.PlatformList()
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
      Ocean(name: "Arctic"),
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
