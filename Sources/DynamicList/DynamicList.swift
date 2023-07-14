import SwiftUI
import UIKit

public struct DynamicList<Section: Hashable, Item: Hashable>: UIViewRepresentable {

  public typealias SelectionAction = DynamicListView<Section, Item>.SelectionAction
  public typealias CellProviderContext = DynamicListView<Section, Item>.CellProviderContext

  private let layout: @MainActor () -> UICollectionViewCompositionalLayout

  private let cellProvider: (CellProviderContext) -> UICollectionViewCell

  private var selectionHandler: (@MainActor (SelectionAction) -> Void)? = nil
  private var incrementalContentLoader: (@MainActor () async throws -> Void)? = nil
  private let data: [Section: [Item]]

  public init(
    data: [Section: [Item]],
    layout: @escaping @MainActor () -> UICollectionViewCompositionalLayout,
    cellProvider: @escaping (
      DynamicListView<Section, Item>.CellProviderContext
    ) -> UICollectionViewCell
  ) {
    self.data = data
    self.layout = layout
    self.cellProvider = cellProvider
  }

  public func makeUIView(context: Context) -> DynamicListView<Section, Item> {

    let listView: DynamicListView<Section, Item> = .init(layout: layout())

    listView.setUp(cellProvider: cellProvider)

    if let selectionHandler {
      listView.setSelectionHandler(selectionHandler)
    }

    if let incrementalContentLoader {
      listView.setIncrementalContentLoader(incrementalContentLoader)
    }

    for element in data {
      listView.setContents(element.value, inSection: element.key)
    }

    return listView
  }

  public func updateUIView(_ listView: DynamicListView<Section, Item>, context: Context) {
    for element in data {
      listView.setContents(element.value, inSection: element.key)
    }
  }

  public func selectionHandler(
    _ handler: @escaping @MainActor (DynamicListView<Section, Item>.SelectionAction) -> Void
  ) -> Self {
    var modified = self
    modified.selectionHandler = handler
    return modified
  }

  public func incrementalContentLoading(_ loader: @escaping @MainActor () async throws -> Void)
    -> Self
  {
    var modified = self
    modified.incrementalContentLoader = loader
    return modified
  }
}

#if DEBUG
struct DynamicList_Previews: PreviewProvider {

  enum Section: CaseIterable {
    case AAAAA
  }

  static let layout: UICollectionViewCompositionalLayout = {

    let item = NSCollectionLayoutItem(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(0.25),
        heightDimension: .estimated(100)
      )
    )

    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(100)
      ),
      subitem: item,
      count: 2
    )

    group.interItemSpacing = .fixed(16)

    // Create a section using the defined group
    let section = NSCollectionLayoutSection(group: group)

    section.contentInsets = .init(top: 0, leading: 24, bottom: 0, trailing: 24)
    section.interGroupSpacing = 24

    // Create a compositional layout using the defined section
    let layout = UICollectionViewCompositionalLayout(section: section)

    return layout
  }()

  static var previews: some View {
    DynamicList<Section, String>(
      data: [.AAAAA: ["a", "b", "c"]],
      layout: { Self.layout }
    ) { context in
      let cell = context.cell { _ in
        Text(context.data)
      }
      .highlightAnimation(.shrink())

      return cell
    }
    .selectionHandler { _ in

    }
    .incrementalContentLoading {

    }

  }
}
#endif
