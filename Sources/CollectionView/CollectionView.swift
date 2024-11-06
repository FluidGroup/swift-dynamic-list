import IndexedCollection
import SwiftUI


/// Still searching better name
/// - built on top of SwiftUI only
@available(iOS 16, *)
public struct CollectionView<
  DataSource: CollectionViewDataSource,
  Layout: CollectionViewLayoutType
>: View {

  private let dataSource: DataSource
  private let layout: Layout

  public init(
    dataSource: DataSource,
    layout: Layout
  ) {
    self.dataSource = dataSource
    self.layout = layout
  }

  public var body: some View {

    self.dataSource
      .modifier(layout)

  }

}

extension EnvironmentValues {
  @Entry public var collectionView_isSelected: Bool = false
}

extension EnvironmentValues {
  @Entry public var collectionView_updateSelection: (Bool) -> Void = { _ in }
}
