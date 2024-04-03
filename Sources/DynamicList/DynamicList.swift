import SwiftUI
import UIKit

public enum Selection<Data: Hashable> {
  case single(Data)
  case multiple(Set<Data>)
}

public struct DynamicList<Section: Hashable, Item: Hashable>: UIViewRepresentable {

  public struct ScrollTarget {
    public let item: Item
    public let position: UICollectionView.ScrollPosition
    public let animated: Bool
    public let skipCondition: @MainActor (UIScrollView) -> Bool

    public init(
      item: Item,
      position: UICollectionView.ScrollPosition = .centeredVertically,
      skipCondition: @escaping @MainActor (UIScrollView) -> Bool,
      animated: Bool
    ) {
      self.item = item
      self.position = position
      self.animated = animated
      self.skipCondition = skipCondition
    }
  }

  private var selection: Binding<Selection<Item>?>?

  public typealias SelectionAction = DynamicListView<Section, Item>.SelectionAction
  public typealias CellProviderContext = DynamicListView<Section, Item>.CellProviderContext

  private let layout: @MainActor () -> UICollectionViewLayout

  private let cellProvider: (CellProviderContext) -> UICollectionViewCell

  private var selectionHandler: (@MainActor (SelectionAction) -> Void)? = nil
  private var scrollHandler: (@MainActor (UIScrollView, DynamicListViewScrollAction) -> Void)? = nil

  private var incrementalContentLoader: (@MainActor () async throws -> Void)? = nil
  private var onLoadHandler: (@MainActor (DynamicListView<Section, Item>) -> Void)? = nil
  private let snapshot: NSDiffableDataSourceSnapshot<Section, Item>

  private let scrollDirection: UICollectionView.ScrollDirection
  private let contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior
  private let cellStates: [Item: CellState]

  private var scrollingTarget: ScrollTarget?

  public init(
    snapshot: NSDiffableDataSourceSnapshot<Section, Item>,
    selection: Binding<Selection<Item>?>? = nil,
    cellStates: [Item: CellState] = [:],
    layout: @escaping @MainActor () -> UICollectionViewLayout,
    scrollDirection: UICollectionView.ScrollDirection,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic,
    cellProvider: @escaping (
      DynamicListView<Section, Item>.CellProviderContext
    ) -> UICollectionViewCell
  ) {
    self.snapshot = snapshot
    self.layout = layout
    self.scrollDirection = scrollDirection
    self.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
    self.cellProvider = cellProvider
    self.selection = selection
    self.cellStates = cellStates
  }

  public func scrolling(to item: ScrollTarget?) -> Self {
    var modified = self
    modified.scrollingTarget = item
    return modified
  }

  public func makeUIView(context: Context) -> DynamicListView<Section, Item> {

    let listView: DynamicListView<Section, Item> = .init(
      layout: layout(),
      scrollDirection: scrollDirection,
      contentInsetAdjustmentBehavior: contentInsetAdjustmentBehavior
    )

    listView.setUp(cellProvider: cellProvider)

    listView.setContents(snapshot: snapshot)

    if let scrollingTarget {

      listView.scroll(
        to: scrollingTarget.item,
        at: scrollingTarget.position,
        skipCondition: scrollingTarget.skipCondition,
        animated: scrollingTarget.animated
      )
    }

    onLoadHandler?(listView)

    return listView
  }

  public func updateUIView(_ listView: DynamicListView<Section, Item>, context: Context) {

    listView.setContents(snapshot: snapshot)

    listView.resetState()

    for (item, state) in cellStates {
      listView._setState(cellState: state, for: item)
    }

    if let selection {

      switch selection.wrappedValue {
      case .none:
        // TODO: deselect all of selected items
        break
      case .single(let data):
        listView.setAllowsMultipleSelection(false)
        listView.select(data: data, animated: false, scrollPosition: [])
      case .multiple(let dataSet):
        // TODO: reset before selecting
        listView.setAllowsMultipleSelection(true)
        for data in dataSet {
          listView.select(data: data, animated: false, scrollPosition: [])
        }
      }
    }

    if let selectionHandler {
      listView.setSelectionHandler(selectionHandler)
    } else {
      listView.setSelectionHandler({ _ in })
    }

    if let incrementalContentLoader {
      listView.setIncrementalContentLoader(incrementalContentLoader)
    } else {
      listView.setIncrementalContentLoader { }
    }

    if let scrollHandler {
      listView.setScrollHandler(scrollHandler)
    } else {
      listView.setScrollHandler({ _, _ in })
    }

    if let scrollingTarget {
      listView.scroll(
        to: scrollingTarget.item,
        at: scrollingTarget.position,
        skipCondition: scrollingTarget.skipCondition,
        animated: scrollingTarget.animated
      )
    }
  }

  public consuming func selectionHandler(
    _ handler: @escaping @MainActor (DynamicListView<Section, Item>.SelectionAction) -> Void
  ) -> Self {
    self.selectionHandler = handler
    return self
  }

  public consuming func scrollHandler(
    _ handler: @escaping @MainActor (UIScrollView, DynamicListViewScrollAction) -> Void
  ) -> Self {
    self.scrollHandler = handler
    return self
  }

  public consuming func incrementalContentLoading(_ loader: @escaping @MainActor () async throws -> Void)
    -> Self
  {
    incrementalContentLoader = loader
    return self
  }

  public consuming func onLoad(_ handler: @escaping @MainActor (DynamicListView<Section, Item>) -> Void)
    -> Self
  {
    onLoadHandler = handler
    return self
  }

}

#if DEBUG
struct DynamicList_Previews: PreviewProvider {

  enum Section: CaseIterable {
    case a
    case b
    case c
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
      snapshot: {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.a, .b, .c])
        snapshot.appendItems(["A"], toSection: .a)
        snapshot.appendItems(["B"], toSection: .b)
        snapshot.appendItems(["C"], toSection: .c)
        return snapshot
      }(),
      cellStates: [
        "A": {
          var cellState = CellState()
          cellState.isArchived = true
          return cellState
        }()
      ],
      layout: { Self.layout },
      scrollDirection: .vertical
    ) { context in
      let cell = context.cell { _, customState in
        HStack {
          Text(context.data)
          if customState.isArchived {
            Text("archived")
          }
        }
      }
      .highlightAnimation(.shrink())

      return cell
    }
    .selectionHandler { value in
      print(value)
    }
    .incrementalContentLoading {

    }
    .onLoad { view in
      print(view)
    }

  }
}

enum IsArchivedKey: CustomStateKey {
  static var defaultValue: Bool { false }

  typealias Value = Bool
}

extension CellState {
  var isArchived: Bool {
    get { self[IsArchivedKey.self] }
    set { self[IsArchivedKey.self] = newValue }
  }
}

#endif
