import SwiftUI

@testable import CollectionView

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
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected?.id,
              onChange: { e in
                selected = e
              }),
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
        },
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
        content: {

          Text("Static content")
            .overlay(content: {

            })

          Text("📱❄️")

          SelectableForEach(
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

          SelectableForEach(
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

#Preview("Custom List / Single selection") {

  struct Book: View {

    @State var selected: Item?

    var body: some View {
      CollectionView(
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected?.id,
              onChange: { e in
                selected = e
              }),
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
        },
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
        content: {
          SelectableForEach(
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
          )
        },
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
    content: {
      SelectableForEach(
        data: Item.mock(),
        selection: .disabled(),
        cell: { index, item in
          HStack {
            Text(index.description)
            Text(item.title)
          }
        }
      )
    },
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

#Preview("SelectableForEach") {

  struct Book: View {

    @State var selected: Item?

    var body: some View {
      SelectableForEach(
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
    }
  }

  return Book()

}
