import SwiftUI
import UIKit

/**
 A key using types that brings custom state into cell.

 ```swift
 enum IsArchivedKey: CustomStateKey {
   typealias Value = Bool

   static var defaultValue: Bool { false }
 }
 ```

 ```swift
 extension CellState {
   var isArchived: Bool {
     get { self[IsArchivedKey.self] }
     set { self[IsArchivedKey.self] = newValue }
   }
 }
 ```
 */
public protocol CustomStateKey {
  associatedtype Value

  static var defaultValue: Value { get }
}

/**
 Additional cell state storage.
 Refer `CustomStateKey` to use your own state for cell.
 */
public struct CellState {

  public static let empty = CellState()

  private var stateMap: [AnyKeyPath : Any] = [:]

  init() {

  }

  public subscript <T: CustomStateKey>(key: T.Type) -> T.Value {
    get {
      stateMap[\T.self] as? T.Value ?? T.defaultValue
    }
    set {
      stateMap[\T.self] = newValue
    }
  }

}

/// Preimplemented list view using UICollectionView and UICollectionViewCompositionalLayout.
/// - Supports dynamic content update
/// - Self cell sizing
/// - Update sizing using ``DynamicSizingCollectionViewCell``.
///
/// - TODO: Currently supported only vertical scrolling.
@available(iOS 13, *)
public final class DynamicListView<Section: Hashable, Data: Hashable>: UIView,
  UICollectionViewDelegate
{

  public enum SelectionAction {
    case didSelect(Data, IndexPath)
    case didDeselect(Data, IndexPath)
  }

  @MainActor
  public struct SupplementaryViewProviderContext {

    public var collectionView: UICollectionView {
      _collectionView
    }

    unowned let _collectionView: CollectionView

    public let indexPath: IndexPath
    public let kind: String

  }

  @MainActor
  public struct CellProviderContext {

    public var collectionView: UICollectionView {
      _collectionView
    }

    unowned let _collectionView: CollectionView

    public let data: Data
    public let indexPath: IndexPath
    private let cellState: CellState

    init(_collectionView: CollectionView, data: Data, indexPath: IndexPath, cellState: CellState) {
      self._collectionView = _collectionView
      self.data = data
      self.indexPath = indexPath
      self.cellState = cellState
    }

    public func dequeueReusableCell<Cell: UICollectionViewCell>(_ cellType: Cell.Type) -> Cell {
      return _collectionView.dequeueReusableCell(
        withReuseIdentifier: _typeName(Cell.self),
        for: indexPath
      ) as! Cell
    }

    public func dequeueDefaultCell() -> VersatileCell {
      return _collectionView.dequeueReusableCell(
        withReuseIdentifier: "DynamicSizingCollectionViewCell",
        for: indexPath
      ) as! VersatileCell
    }

    public func cell<Configuration: UIContentConfiguration>(
      file: StaticString = #file,
      line: UInt = #line,
      column: UInt = #column,
      reuseIdentifier: String? = nil,
      withConfiguration contentConfiguration: @escaping @MainActor (
        VersatileCell, UICellConfigurationState, CellState
      ) -> Configuration
    ) -> VersatileCell {

      let _reuseIdentifier = reuseIdentifier ?? "\(file):\(line):\(column)"

      if _collectionView.cellForIdentifiers.contains(_reuseIdentifier) == false {

        Log.debug(.generic, "Register Cell : \(_reuseIdentifier)")

        _collectionView.register(VersatileCell.self, forCellWithReuseIdentifier: _reuseIdentifier)
      }

      let cell =
        _collectionView.dequeueReusableCell(
          withReuseIdentifier: _reuseIdentifier,
          for: indexPath
        ) as! VersatileCell

      cell.contentConfiguration = contentConfiguration(cell, cell.configurationState, cellState)
      cell._updateConfigurationHandler = { cell, state, customState in
        cell.contentConfiguration = contentConfiguration(cell, state, customState)
      }

      return cell

    }

    public func cell(
      file: StaticString = #file,
      line: UInt = #line,
      column: UInt = #column,
      reuseIdentifier: String? = nil,
      @ViewBuilder content: @escaping @MainActor (UICellConfigurationState, CellState) -> some View
    ) -> VersatileCell {

      if #available(iOS 16, *) {
        return self.cell(
          file: file,
          line: line,
          column: column,
          reuseIdentifier: reuseIdentifier,
          withConfiguration: { cell, state, customState in
            UIHostingConfiguration { content(state, customState).environment(\.versatileCell, cell) }.margins(
              .all,
              0
            )
          }
        )
      } else {
        return self.cell(
          file: file,
          line: line,
          column: column,
          reuseIdentifier: reuseIdentifier,
          withConfiguration: { cell, state, customState in
            HostingConfiguration { content(state, customState).environment(\.versatileCell, cell) }
          }
        )
      }

    }

  }

  public var scrollView: UIScrollView {
    _collectionView
  }

  public var collectionView: UICollectionView {
    _collectionView
  }

  private let _collectionView: CollectionView

  public var layout: UICollectionViewLayout {
    _collectionView.collectionViewLayout
  }

  private var _cellProvider: ((CellProviderContext) -> UICollectionViewCell)?

  private var _selectionHandler: @MainActor (SelectionAction) -> Void = { _ in }
  private var _incrementalContentLoader: @MainActor () async throws -> Void = {}

  private var dataSource: UICollectionViewDiffableDataSource<Section, Data>!

  // TODO: remove CellState following cell deletion.
  private var stateMap: [Data : CellState] = [:]

  private let contentPagingTrigger: ContentPagingTrigger

  public init(
    layout: UICollectionViewLayout,
    scrollDirection: UICollectionView.ScrollDirection,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
  ) {

    self._collectionView = CollectionView.init(frame: .null, collectionViewLayout: layout)
    self.contentPagingTrigger = .init(
      scrollView: _collectionView,
      trackingScrollDirection: {
        switch scrollDirection {
        case .vertical:
          return .down
        case .horizontal:
          return .right
        @unknown default:
          return .down
        }
      }(),
      leadingScreensForBatching: 1
    )

    super.init(frame: .null)

    self.backgroundColor = .clear
    self._collectionView.backgroundColor = .clear
    self._collectionView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior

    self.addSubview(_collectionView)

    _collectionView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      _collectionView.topAnchor.constraint(equalTo: topAnchor),
      _collectionView.rightAnchor.constraint(equalTo: rightAnchor),
      _collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
      _collectionView.leftAnchor.constraint(equalTo: leftAnchor),
    ])

    let dataSource = UICollectionViewDiffableDataSource<Section, Data>(
      collectionView: collectionView,
      cellProvider: { [unowned self] collectionView, indexPath, item in

        guard let provider = self._cellProvider else {
          assertionFailure("Needs setup before start using.")
          return UICollectionViewCell(frame: .zero)
        }

        let data = item

        let state = stateMap[data] ?? .init()

        let context = CellProviderContext.init(
          _collectionView: collectionView as! CollectionView,
          data: data,
          indexPath: indexPath,
          cellState: state
        )

        let cell = provider(context)

        if let versatileCell = cell as? VersatileCell {
          versatileCell.customState = state
          versatileCell.updateContent(using: state)
        }

        return cell

      }
    )

    self.dataSource = dataSource

    self._collectionView.register(
      VersatileCell.self,
      forCellWithReuseIdentifier: "DynamicSizingCollectionViewCell"
    )
    self._collectionView.delegate = self
    self.collectionView.dataSource = dataSource
    self._collectionView.delaysContentTouches = false
    //    self.collectionView.isPrefetchingEnabled = false
    //    self.collectionView.prefetchDataSource = nil

    #if swift(>=5.7)
    if #available(iOS 16.0, *) {
      assert(self._collectionView.selfSizingInvalidation == .enabled)
    }
    #endif

  }

  public convenience init(
    compositionalLayout: UICollectionViewCompositionalLayout,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
  ) {
    self.init(
      layout: compositionalLayout,
      scrollDirection: compositionalLayout.configuration.scrollDirection,
      contentInsetAdjustmentBehavior: contentInsetAdjustmentBehavior
    )
  }

  public convenience init(
    scrollDirection: UICollectionView.ScrollDirection,
    spacing: CGFloat = 0,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
  ) {

    let layout: UICollectionViewCompositionalLayout

    switch scrollDirection {
    case .vertical:

      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(100)
        ),
        subitems: [
          NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
              widthDimension: .fractionalWidth(1.0),
              heightDimension: .estimated(100)
            )
          )
        ]
      )

      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = spacing

      let configuration = UICollectionViewCompositionalLayoutConfiguration()
      configuration.scrollDirection = scrollDirection

      layout = UICollectionViewCompositionalLayout.init(section: section)

    case .horizontal:

      let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: .init(widthDimension: .estimated(100), heightDimension: .fractionalHeight(1)),
        subitems: [
          .init(
            layoutSize: .init(
              widthDimension: .estimated(100),
              heightDimension: .fractionalHeight(1)
            )
          )
        ]
      )

      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = spacing

      let configuration = UICollectionViewCompositionalLayoutConfiguration()
      configuration.scrollDirection = scrollDirection

      layout = UICollectionViewCompositionalLayout.init(
        section: section,
        configuration: configuration
      )

    @unknown default:
      fatalError()
    }

    self.init(
      layout: layout,
      scrollDirection: layout.configuration.scrollDirection,
      contentInsetAdjustmentBehavior: contentInsetAdjustmentBehavior
    )

  }

  public
    required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  public func registerCell<Cell: UICollectionViewCell>(
    _ cellType: Cell.Type
  ) {
    _collectionView.register(
      cellType,
      forCellWithReuseIdentifier: _typeName(Cell.self)
    )
  }

  public func setUp(
    cellProvider: @escaping (CellProviderContext) -> UICollectionViewCell
  ) {
    _cellProvider = cellProvider
  }

  public func setAllowsMultipleSelection(_ allows: Bool) {
    _collectionView.allowsMultipleSelection = allows
  }

  public func resetState() {
    stateMap.removeAll()

    for cell in _collectionView.visibleCells {

      if let versatileCell = cell as? VersatileCell {
        versatileCell.customState = .empty
        versatileCell.updateContent(using: .empty)
      }

    }
  }

  public func state<Key: CustomStateKey>(for data: Data, key: Key.Type) -> Key.Value? {
    return stateMap[data]?[Key.self] as? Key.Value
  }

  func _setState(cellState: CellState, for data: Data) {
    guard let indexPath = dataSource.indexPath(for: data) else {
      return
    }

    stateMap[data] = cellState

    guard let cell = _collectionView.cellForItem(at: indexPath) as? VersatileCell else {
      return
    }

    cell.customState = cellState
    cell.updateContent(using: cellState)
  }

  @available(iOS 15.0, *)
  public func setState<Key: CustomStateKey>(_ value: Key.Value, key: Key.Type, for data: Data) {

    guard let indexPath = dataSource.indexPath(for: data) else {
      return
    }

    var cellState = stateMap[data, default: .empty]
    cellState[Key.self] = value
    stateMap[data] = cellState

    guard let cell = _collectionView.cellForItem(at: indexPath) as? VersatileCell else {
      return
    }

    cell.customState = cellState
    cell.updateContent(using: cellState)

  }

  public func select(data: Data, animated: Bool, scrollPosition: UICollectionView.ScrollPosition) {

    guard let indexPath = dataSource.indexPath(for: data) else {
      return
    }

    _collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)

  }

  public func supplementaryViewHandler(_ handler: @escaping @MainActor (SupplementaryViewProviderContext) -> UICollectionReusableView) {

    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in

      let context = SupplementaryViewProviderContext(_collectionView: collectionView as! CollectionView, indexPath: indexPath, kind: kind)

      let view = handler(context)

      return view
    }

  }

  public func setIncrementalContentLoader(
    _ loader: @escaping @MainActor () async throws -> Void
  ) {
    _incrementalContentLoader = loader

    contentPagingTrigger.onBatchFetch = { [weak self] in
      guard let self = self else { return }
      do {
        try await self._incrementalContentLoader()
      } catch {

      }
    }

  }

  public func setSelectionHandler(
    _ handler: @escaping @MainActor (SelectionAction) -> Void
  ) {
    _selectionHandler = handler
  }

  public func setContents(
    snapshot: NSDiffableDataSourceSnapshot<Section, Data>,
    animatedUpdating: Bool = true
  ) {

    dataSource.apply(snapshot, animatingDifferences: animatedUpdating)

  }

  /**
   Displays cells with given contents.
   CollectionView will update its cells partially using DiffableDataSources.
   */
  public func setContents(_ contents: [Data], animatedUpdating: Bool = true)
  where Section == DynamicCompositionalLayoutSingleSection {

    if #available(iOS 14, *) {

    } else {
      // fix crash
      // https://developer.apple.com/forums/thread/126742
      let currentSnapshot = self.dataSource.snapshot()
      if currentSnapshot.numberOfItems == 0, contents.isEmpty {
        return
      }
    }

    var newSnapshot = NSDiffableDataSourceSnapshot<Section, Data>.init()
    newSnapshot.appendSections([.main])
    newSnapshot.appendItems(contents, toSection: .main)

    setContents(snapshot: newSnapshot, animatedUpdating: animatedUpdating)

  }

  public func snapshot() -> NSDiffableDataSourceSnapshot<Section, Data> {
    dataSource.snapshot()
  }

  public func setContents(
    _ contents: [Data],
    inSection section: Section,
    animatedUpdating: Bool = true
  ) {

    var snapshot = dataSource.snapshot()

    snapshot.deleteSections([section])
    snapshot.appendSections([section])
    snapshot.appendItems(contents, toSection: section)

    setContents(snapshot: snapshot, animatedUpdating: animatedUpdating)

  }

  public func setContentInset(_ insets: UIEdgeInsets) {
    _collectionView.contentInset = insets
  }

  public func scroll(
    to data: Data,
    at scrollPosition: UICollectionView.ScrollPosition,
    skipCondition: @escaping @MainActor (UIScrollView) -> Bool,
    animated: Bool
  ) {
    guard let indexPath = dataSource.indexPath(for: data) else {
      return
    }

    if skipCondition(_collectionView) {
      return
    }

    _collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
  }

  // MARK: - UICollectionViewDelegate

  public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    let item = dataSource.itemIdentifier(for: indexPath)!
    _selectionHandler(.didSelect(item, indexPath))
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didDeselectItemAt indexPath: IndexPath
  ) {
    let item = dataSource.itemIdentifier(for: indexPath)!
    _selectionHandler(.didDeselect(item, indexPath))
  }

}

internal final class CollectionView: UICollectionView {

  fileprivate var cellForIdentifiers: Set<String> = .init()

  override func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
    cellForIdentifiers.insert(identifier)
    super.register(cellClass, forCellWithReuseIdentifier: identifier)
  }
}

@available(iOS 13, *)
public typealias DynamicCompositionalLayoutSingleSectionView<Data: Hashable> =
  DynamicListView<DynamicCompositionalLayoutSingleSection, Data>

public enum DynamicCompositionalLayoutSingleSection: Hashable {
  case main
}

private enum CellContextKey: EnvironmentKey {
  static var defaultValue: VersatileCell?
}

extension EnvironmentValues {
  public var versatileCell: VersatileCell? {
    get { self[CellContextKey.self] }
    set { self[CellContextKey.self] = newValue }
  }
}

