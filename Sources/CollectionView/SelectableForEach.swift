import SwiftUI
import IndexedCollection

public struct SelectableForEach<
  Data: RandomAccessCollection,
  Cell: View,
  Selection: CollectionViewSelection<Data.Element>
>: View where Data.Element: Identifiable {
  
  public let data: Data
  public let selection: Selection
  private let cell: (Data.Index, Data.Element) -> Cell
  
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

extension EnvironmentValues {
  @Entry public var collectionView_isSelected: Bool = false
}

extension EnvironmentValues {
  @Entry public var collectionView_updateSelection: (Bool) -> Void = { _ in }
}

