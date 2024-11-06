import SwiftUI
import IndexedCollection

public protocol CollectionViewDataSource: View {

}

public enum CollectionViewDataSources {

  public struct Unified<Content: View>: CollectionViewDataSource {

    private let content: Content

    public init(
      @ViewBuilder content: () -> Content
    ) {
      self.content = content()
    }

    public var body: some View {
      content
    }
  }

  public struct UsingCollection<
    Data: RandomAccessCollection,
    Cell: View,
    Selection: CollectionViewSelection<Data.Element>
  >: CollectionViewDataSource, View where Data.Element: Identifiable {

    public let data: Data
    private let cell: (Data.Index, Data.Element) -> Cell
    public let selection: Selection

    public init(
      data: Data,
      selection: Selection,
      cell: @escaping (Data.Index, Data.Element) -> Cell
    ) {
      self.data = data
      self.cell = cell
      self.selection = selection
    }

    public var body: some View {
      ForEach(IndexedCollection(data)) { element in

        let isSelected: Bool = selection.isSelected(for: element.id)
        let isDisabled: Bool = !selection.isEnabled(for: element.id)

        cell(element.index, element.value)
          .disabled(isDisabled)
          .environment(\.collectionView_isSelected, isSelected)
          .environment(
            \.collectionView_updateSelection,
            { [selection] isSelected in
              selection.update(isSelected: isSelected, for: element.value)
            })
      }
    }

  }

}

extension CollectionViewDataSource {

  public static func unified<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> Self where Self == CollectionViewDataSources.Unified<Content> {
    .init(content: content)
  }

  public static func collection<
    Data: RandomAccessCollection,
    Cell: View,
    Selection: CollectionViewSelection<Data.Element>
  >(
    data: Data,
    selection: Selection,
    cell: @escaping (Data.Index, Data.Element) -> Cell
  ) -> Self
  where
    Self == CollectionViewDataSources.UsingCollection<Data, Cell, Selection>,
    Data.Element: Identifiable
  {
    .init(data: data, selection: selection, cell: cell)
  }

}
