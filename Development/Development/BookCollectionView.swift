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
        layout: .list
          .contentPadding(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
          .separator(
            separator: {
              RoundedRectangle(cornerRadius: 8)
                .fill(.secondary)
                .frame(height: 8)
                .padding(.horizontal, 20)
            }
          ),
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected,
              onChange: { e in
                selected = e
              }),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
        }
      )

    }
  }

}

struct BookCollectionViewSingleSectionNoSeparator: View, PreviewProvider {

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
        layout: .list,
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected,
              onChange: { e in
                selected = e
              }),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
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
        layout: .list,
        content: {

          Text("Static content")
            .overlay(content: {

            })

          Text("📱❄️")

          SelectableForEach(
            data: Item.mock(10),
            selection: .single(
              selected: selected,
              onChange: { e in
                selected = e
              }),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )

          Text("📱❄️")

          SelectableForEach(
            data: Item.mock(10),
            selection: .single(
              selected: selected2,
              onChange: { e in
                selected2 = e
              }),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )

          Text("📱❄️")

          ForEach(Item.mock(10)) { item in
            Cell(index: item.id, item: item)
          }

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
        layout: .list.separator {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 2)
            .padding(.horizontal, 20)
        },
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected,
              onChange: { e in
                selected = e
              }),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
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
        layout: .list.separator {
          RoundedRectangle(cornerRadius: 8)
            .fill(.secondary)
            .frame(height: 2)
            .padding(.horizontal, 20)
        },
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .multiple(
              selected: selected,
              canSelectMore: selected.count < 3,
              onChange: { e, action in
                switch action {
                case .selected:
                  selected.insert(e)
                case .deselected:
                  selected.remove(e)
                }
              }),
            selectionIdentifier: \.id,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
        }
      )
    }
  }

  return Book()
}

struct BookPlatformList: View, PreviewProvider {
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
        layout: CollectionViewLayouts.PlatformListVanilla(),
        content: {
          SelectableForEach(
            data: Item.mock(),
            selection: .single(
              selected: selected,
              onChange: { e in
                selected = e
              }
            ),
            selectionIdentifier: \.self,
            cell: { index, item in
              Cell(index: index, item: item)
            }
          )
        }
      )
    }
  }
}

#Preview("PlatformList") {
  BookPlatformList()
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

#Preview("Inline Single selection") {

  struct Preview: View {

    @State var selected: Item.ID?

    var body: some View {

      SelectableForEach(
        data: Item.mock(10),
        selection: .single(
          selected: selected,
          onChange: { selected in
            self.selected = selected
          }),
        selectionIdentifier: \.id,
        cell: { index, item in
          Cell(index: index, item: item)
        }
      )

    }
  }

  return Preview()
}

#Preview("Inline Multiple selection") {

  struct Preview: View {

    @State var selected: Set<Item.ID> = .init()

    var body: some View {

      SelectableForEach(
        data: Item.mock(10),
        selection: .multiple(
          selected: selected,
          canSelectMore: selected.count < 3,
          onChange: { e, action in
            switch action {
            case .selected:
              selected.insert(e)
            case .deselected:
              selected.remove(e)
            }
          }),
        selectionIdentifier: \.id,
        cell: { index, item in
          Cell(index: index, item: item)
        }
      )

    }
  }

  return Preview()
}

#Preview("Scrollable Multiple selection") {
  
  struct Preview: View {
    
    @State var selected: Set<Item.ID> = .init()
    
    var body: some View {
      
      ScrollView {        
        
        header
          .padding(.horizontal, 20)
        
        SelectableForEach(
          data: Item.mock(10),
          selection: .multiple(
            selected: selected,
            canSelectMore: selected.count < 3,
            onChange: { e, action in
              switch action {
              case .selected:
                selected.insert(e)
              case .deselected:
                selected.remove(e)
              }
            }),
          selectionIdentifier: \.id,
          cell: { index, item in
            Cell(index: index, item: item)
          }
        )
      }
      
    }
    
    private var header: some View {
      ZStack {      
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(white: 0, opacity: 0.2))
        Text("Header")
      }
      .frame(height: 120)
    }
  }
  
  return Preview()
}
