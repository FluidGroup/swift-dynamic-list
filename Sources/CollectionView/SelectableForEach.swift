import SwiftUI
import IndexedCollection

/**
 A structure that computes views on demand from an underlying collection of identified data with selection funtion.
 The contents that produced by ForEach have environment values that indicate the selection state.
 
 ```
 @Environment(\.collectionView_isSelected) var isSelected: Bool
 @Environment(\.collectionView_updateSelection) var updateSelection: (Bool) -> Void
 ```
 */
public struct SelectableForEach<
  Data: RandomAccessCollection,
  Cell: View,
  _Selection: SelectionState<Data.Element>
>: View where Data.Element: Identifiable {
  
  public let data: Data
  public let selection: _Selection
  private let cell: (Data.Index, Data.Element) -> Cell
  
  public init(
    data: Data,
    selection: _Selection,
    cell: @escaping (Data.Index, Data.Element) -> Cell
  ) {
    self.data = data
    self.cell = cell
    self.selection = selection
  }
  
  public var body: some View {
    ForEach(IndexedCollection(data)) { element in
      
      let isSelected: Bool = selection.isSelected(for: element.value.id)
      let isDisabled: Bool = !selection.isEnabled(for: element.id)
      
      selection.applyEnvironments(
        for: cell(element.index, element.value), 
        item: element.value
      )      
    }
  }
  
}

extension EnvironmentValues {
  /**
   A boolean value that indicates whether the cell is selected.
   Provided by the ``SelectableForEach`` view.
   */
  @Entry public var collectionView_isSelected: Bool = false
}

extension EnvironmentValues {
  /**
   A closure that updates the selection state of the cell.
   Provided by the ``SelectableForEach`` view.
   */
  @Entry public var collectionView_updateSelection: (Bool) -> Void = { _ in }
}

