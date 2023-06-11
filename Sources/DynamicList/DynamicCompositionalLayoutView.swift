import SwiftUI
import UIKit

/// Preimplemented list view using UICollectionView and UICollectionViewCompositionalLayout.
/// - Supports dynamic content update
/// - Self cell sizing
/// - Update sizing using ``DynamicSizingCollectionViewCell``.
///
/// - TODO: Currently supported only vertical scrolling.
@available(iOS 13, *)
public final class DynamicCompositionalLayoutView<Section: Hashable, Data: Hashable>: UIView,
  UICollectionViewDelegate
{

  public enum SelectionAction {
    case didSelect(Data)
    case didDeselect(Data)
  }

  @MainActor
  public struct CellProviderContext {

    public var collectionView: UICollectionView {
      _collectionView
    }

    unowned let _collectionView: CollectionView

    public let data: Data
    public let indexPath: IndexPath

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
      reuseIdentifier: String,
      withConfiguration contentConfiguration: @escaping @MainActor (
        VersatileCell, UICellConfigurationState
      ) -> Configuration
    ) -> some UICollectionViewCell {

      if _collectionView.cellForIdentifiers.contains(reuseIdentifier) == false {

        Log.debug(.generic, "Register Cell : \(reuseIdentifier)")

        _collectionView.register(VersatileCell.self, forCellWithReuseIdentifier: reuseIdentifier)
      }

      let cell =
        _collectionView.dequeueReusableCell(
          withReuseIdentifier: reuseIdentifier,
          for: indexPath
        ) as! VersatileCell

      cell.contentConfiguration = contentConfiguration(cell, cell.configurationState)
      cell._updateConfigurationHandler = { cell, state in
        cell.contentConfiguration = contentConfiguration(cell, state)
      }

      return cell

    }

    public func cell(
      reuseIdentifier: String,
      @ViewBuilder content: @escaping @MainActor (UICellConfigurationState) -> some View
    ) -> some UICollectionViewCell {

      if #available(iOS 16, *) {
        self.cell(
          reuseIdentifier: reuseIdentifier,
          withConfiguration: { cell, state in
            UIHostingConfiguration { content(state).environment(\.versatileCell, cell) }.margins(
              .all,
              0
            )
          }
        )
      } else {
        self.cell(
          reuseIdentifier: reuseIdentifier,
          withConfiguration: { cell, state in
            HostingConfiguration { content(state).environment(\.versatileCell, cell) }
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

  public var layout: UICollectionViewCompositionalLayout {
    _collectionView.collectionViewLayout as! UICollectionViewCompositionalLayout
  }

  private var _cellProvider: ((CellProviderContext) -> UICollectionViewCell)?

  private var _selectionHandler: @MainActor (SelectionAction) -> Void = { _ in }
  private var _incrementalContentLoader: @MainActor () async throws -> Void = {}

  private var dataSource: UICollectionViewDiffableDataSource<Section, Data>!

  private let contentPagingTrigger: ContentPagingTrigger

  public init(
    layout: UICollectionViewCompositionalLayout,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
  ) {

    self._collectionView = CollectionView.init(frame: .null, collectionViewLayout: layout)
    self.contentPagingTrigger = .init(
      scrollView: _collectionView,
      trackingScrollDirection: {
        switch layout.configuration.scrollDirection {
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

        let context = CellProviderContext.init(
          _collectionView: collectionView as! CollectionView,
          data: data,
          indexPath: indexPath
        )

        return provider(context)

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

    self.init(layout: layout, contentInsetAdjustmentBehavior: contentInsetAdjustmentBehavior)

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
    animated: Bool
  ) {
    guard let indexPath = dataSource.indexPath(for: data) else {
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
    _selectionHandler(.didSelect(item))
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didDeselectItemAt indexPath: IndexPath
  ) {
    let item = dataSource.itemIdentifier(for: indexPath)!
    _selectionHandler(.didDeselect(item))
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
  DynamicCompositionalLayoutView<DynamicCompositionalLayoutSingleSection, Data>

public enum DynamicCompositionalLayoutSingleSection: Hashable {
  case main
}

/// - Provides a timing to trigger batch fetching (adding more items)
/// - According to scrolling
/// - Multiple edge supported - up, down.
///
/// Observing the target scroll view's content-offset.
///
/// - Author: Muukii
@available(iOS 13, *)
@MainActor
final class ContentPagingTrigger {

  public enum TrackingScrollDirection {
    case up
    case down
    case right

    func isMatchDirection(oldContentOffset: CGPoint?, newContentOffset: CGPoint) -> Bool {
      guard let oldContentOffset = oldContentOffset else {
        return false
      }

      switch self {
      case .up:
        return newContentOffset.y < oldContentOffset.y
      case .down:
        return newContentOffset.y > oldContentOffset.y
      case .right:
        return newContentOffset.x > oldContentOffset.x
      }

    }
  }

  // MARK: - Properties

  public var onBatchFetch: (@MainActor () async -> Void)?

  private var currentTask: Task<Void, Never>?

  public var isEnabled: Bool = true

  private var oldContentOffset: CGPoint?

  public let trackingScrollDirection: TrackingScrollDirection

  public let leadingScreensForBatching: CGFloat

  private var offsetObservation: NSKeyValueObservation?
  private var contentSizeObservation: NSKeyValueObservation?

  // MARK: - Initializers

  public init(
    scrollView: UIScrollView,
    trackingScrollDirection: TrackingScrollDirection,
    leadingScreensForBatching: CGFloat = 2
  ) {
    self.leadingScreensForBatching = leadingScreensForBatching
    self.trackingScrollDirection = trackingScrollDirection

    offsetObservation = scrollView.observe(\.contentOffset, options: [.initial, .new]) {
      @MainActor(unsafe) [weak self] scrollView, _ in
      guard let `self` = self else { return }
      self.didScroll(scrollView: scrollView)
    }

    contentSizeObservation = scrollView.observe(\.contentSize, options: [.initial, .new]) {
      @MainActor(unsafe) scrollView, _ in
      //      print(scrollView.contentSize)
    }
  }

  deinit {
    offsetObservation?.invalidate()
    contentSizeObservation?.invalidate()
  }

  // MARK: - Functions

  public func didScroll(scrollView: UIScrollView) {

    guard onBatchFetch != nil else {
      return
    }

    let bounds = scrollView.bounds
    let contentSize = scrollView.contentSize
    let targetOffset = scrollView.contentOffset
    let leadingScreens = leadingScreensForBatching

    guard currentTask == nil else {
      return
    }

    guard
      trackingScrollDirection.isMatchDirection(
        oldContentOffset: oldContentOffset,
        newContentOffset: targetOffset
      )
    else {
      oldContentOffset = scrollView.contentOffset
      return
    }

    oldContentOffset = scrollView.contentOffset

    guard leadingScreens > 0 || bounds != .zero else {
      return
    }

    let viewLength = bounds.size.height
    let offset = targetOffset.y
    let contentLength = contentSize.height

    switch trackingScrollDirection {
    case .up:

      // target offset will always be 0 if the content size is smaller than the viewport
      let hasSmallContent = offset == 0.0 && contentLength < viewLength

      let triggerDistance = viewLength * leadingScreens
      let remainingDistance = offset

      if hasSmallContent || remainingDistance <= triggerDistance {

        trigger()
      }
    case .down:
      // target offset will always be 0 if the content size is smaller than the viewport
      let hasSmallContent = offset == 0.0 && contentLength < viewLength

      let triggerDistance = viewLength * leadingScreens
      let remainingDistance = contentLength - viewLength - offset

      if hasSmallContent || remainingDistance <= triggerDistance {

        trigger()
      }
    case .right:

      let viewWidth = bounds.size.width
      let offsetX = targetOffset.x
      let contentWidth = contentSize.width

      let hasSmallContent = offsetX == 0.0 && contentWidth < viewWidth

      let triggerDistance = viewWidth * leadingScreens
      let remainingDistance = contentWidth - viewWidth - offsetX

      if hasSmallContent || remainingDistance <= triggerDistance {

        trigger()
      }
    }
  }

  private func trigger() {

    guard isEnabled else { return }
    triggerManually()
  }

  public func triggerManually() {

    guard let onBatchFetch else { return }
    guard currentTask == nil else { return }

    let task = Task {
      await onBatchFetch()

      self.currentTask = nil
    }

    currentTask = task
  }
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
