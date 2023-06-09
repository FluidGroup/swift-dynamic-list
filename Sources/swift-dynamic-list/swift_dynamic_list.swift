import SwiftUI
import SwiftUIHosting
import SwiftUISupport
import UIKit

struct CustomList<Content: View>: View {

  let tree: _VariadicView.Tree<VariadicViewProxy, Content>

  init(@ViewBuilder content: () -> Content) {
    self.tree = _VariadicView.Tree(VariadicViewProxy(), content: content)
  }

  var body: some View {
    tree
  }

  struct VariadicViewProxy: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
      _CollectionView(children: children)
    }
  }

}

struct _CollectionView: UIViewRepresentable {

  struct ViewBox: Hashable {

    static func == (lhs: ViewBox, rhs: ViewBox) -> Bool {
      lhs.value.id == rhs.value.id
    }

    let value: _VariadicView.Children.Element

    func hash(into hasher: inout Hasher) {
      value.id.hash(into: &hasher)
    }

    init(_ value: _VariadicView.Children.Element) {
      self.value = value
    }

  }

  typealias View = DynamicCompositionalLayoutView<Int, ViewBox>

  private let views: [ViewBox]

  init(children: _VariadicView.Children) {
    // TODO: stop mapping. accessing directly.
    print(children.map { $0.id })
    self.views = children.map { ViewBox($0) }
  }

  func makeUIView(context: Context) -> View {

    let view = View(scrollDirection: .vertical)

    view.registerCell(DynamicSizingCollectionViewCell.self)
    view.setUp(
      cellProvider: { context in

        let cell = context.dequeueReusableCell(DynamicSizingCollectionViewCell.self)

        if #available(iOS 16, *) {

          cell.contentConfiguration = UIHostingConfiguration(content: {
            context.data.value
          })
          .margins(.all, 0)

        } else {
          cell.contentConfiguration = _Configuration(context.data.value)
        }

        return cell

      },
      actionHandler: { action in

      }
    )
    return view
  }

  func updateUIView(_ uiView: View, context: Context) {
    uiView.setContents(views, inSection: 0)
  }
}

class CollectionView: UICollectionView {

  override func layoutSubviews() {
    super.layoutSubviews()
  }

}

class _UICollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {

  override func invalidateLayout() {
    super.invalidateLayout()
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
    -> UICollectionViewLayoutAttributes?
  {
    super.layoutAttributesForItem(at: indexPath)
  }
}

/// Preimplemented list view using UICollectionView and UICollectionViewCompositionalLayout.
/// - Supports dynamic content update
/// - Self cell sizing
/// - Update sizing using ``DynamicSizingCollectionViewCell``.
///
/// - TODO: Currently supported only vertical scrolling.
@available(iOS 13, *)
final class DynamicCompositionalLayoutView<Section: Hashable, Data: Hashable>: UIView,
  UICollectionViewDelegate
{

  @MainActor
  public struct CellProviderContext {

    public unowned let collectionView: UICollectionView
    public let data: Data
    public let indexPath: IndexPath

    public func dequeueReusableCell<Cell: UICollectionViewCell>(_ cellType: Cell.Type) -> Cell {
      return collectionView.dequeueReusableCell(
        withReuseIdentifier: _typeName(Cell.self),
        for: indexPath
      ) as! Cell
    }

  }

  public enum Action {
    case didSelect(Data)
    case batchFetch((@escaping @MainActor () async -> Void) -> Void)
  }

  public var scrollView: UIScrollView {
    collectionView
  }

  public let collectionView: UICollectionView

  public var layout: UICollectionViewCompositionalLayout {
    collectionView.collectionViewLayout as! UICollectionViewCompositionalLayout
  }

  private var _cellProvider: ((CellProviderContext) -> UICollectionViewCell)?

  private var _actionHandler: @MainActor (Action) -> Void = { action in
    switch action {
    case .didSelect:
      break
    case .batchFetch(let task):
      task {

      }
    }
  }

  private var dataSource: UICollectionViewDiffableDataSource<Section, Data>!

  private let contentPagingTrigger: ContentPagingTrigger

  public init(
    layout: UICollectionViewCompositionalLayout,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
  ) {

    self.collectionView = CollectionView.init(frame: .null, collectionViewLayout: layout)
    self.contentPagingTrigger = .init(
      scrollView: collectionView,
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
    self.collectionView.backgroundColor = .clear
    self.collectionView.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior

    self.addSubview(collectionView)

    collectionView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.rightAnchor.constraint(equalTo: rightAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
      collectionView.leftAnchor.constraint(equalTo: leftAnchor),
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
          collectionView: collectionView,
          data: data,
          indexPath: indexPath
        )

        return provider(context)

      }
    )

    self.dataSource = dataSource

    self.collectionView.delegate = self
    self.collectionView.dataSource = dataSource
    self.collectionView.delaysContentTouches = false
    //    self.collectionView.isPrefetchingEnabled = false
    //    self.collectionView.prefetchDataSource = nil

    contentPagingTrigger.onBatchFetch = { [weak self] in
      guard let self = self else { return }

      await withCheckedContinuation { c in
        self._actionHandler(
          .batchFetch({ task in
            Task {
              await task()
              c.resume()
            }
          })
        )
      }

    }

    #if swift(>=5.7)
    if #available(iOS 16.0, *) {
      assert(self.collectionView.selfSizingInvalidation == .enabled)
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

      layout = _UICollectionViewCompositionalLayout.init(section: section)

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
    collectionView.register(
      cellType,
      forCellWithReuseIdentifier: _typeName(Cell.self)
    )
  }

  public func setUp(
    cellProvider: @escaping (CellProviderContext) -> UICollectionViewCell,
    actionHandler: @escaping @MainActor (Action) -> Void
  ) {

    _actionHandler = actionHandler
    _cellProvider = cellProvider
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
    collectionView.contentInset = insets
  }

  public func scroll(
    to data: Data,
    at scrollPosition: UICollectionView.ScrollPosition,
    animated: Bool
  ) {
    guard let indexPath = dataSource.indexPath(for: data) else {
      return
    }

    collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
  }

  // MARK: - UICollectionViewDelegate

  public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    let item = dataSource.itemIdentifier(for: indexPath)!
    _actionHandler(.didSelect(item))
  }

}

@available(iOS 13, *)
typealias DynamicCompositionalLayoutSingleSectionView<Data: Hashable> =
  DynamicCompositionalLayoutView<DynamicCompositionalLayoutSingleSection, Data>

enum DynamicCompositionalLayoutSingleSection: Hashable {
  case main
}

open class DynamicSizingCollectionViewCell: UICollectionViewCell {

  public override init(
    frame: CGRect
  ) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  public required init?(
    coder: NSCoder
  ) {
    fatalError()
  }

  open override func invalidateIntrinsicContentSize() {
    //    if #available(iOS 16, *) {
    //      // from iOS 16, auto-resizing runs
    //      super.invalidateIntrinsicContentSize()
    //    } else {
    super.invalidateIntrinsicContentSize()
    //      self.layoutWithInvalidatingCollectionViewLayout(animated: true)
    //    }
  }

  public func layoutWithInvalidatingCollectionViewLayout(animated: Bool) {

    guard let collectionView = (superview as? UICollectionView) else {
      return
    }

    if animated {

      UIView.animate(
        withDuration: 0.5,
        delay: 0,
        usingSpringWithDamping: 1,
        initialSpringVelocity: 0,
        options: [
          .beginFromCurrentState,
          .allowUserInteraction,
          .overrideInheritedCurve,
          .overrideInheritedOptions,
          .overrideInheritedDuration,
        ],
        animations: {
          collectionView.collectionViewLayout.invalidateLayout()
          collectionView.layoutIfNeeded()
        },
        completion: { (finish) in

        }
      )

    } else {

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      collectionView.collectionViewLayout.invalidateLayout()
      collectionView.layoutIfNeeded()
      CATransaction.commit()

    }
  }

}

private struct _Configuration<Content: View>: UIContentConfiguration {

  let content: Content

  init(_ content: Content) {
    self.content = content
  }

  func makeContentView() -> UIView & UIContentView {
    _ContentView<Content>(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> _Configuration {
    return self
  }
}

private final class _ContentView<Content: View>: UIView, UIContentView {

  var configuration: UIContentConfiguration {
    didSet {
      // FIXME: assume the type will be mismatched if the content is dynamic.
      let configuration = configuration as! _Configuration<Content>
      updateView(configuration.content)
    }
  }

  private let hostingController: HostingController<Content?>

  init(configuration: _Configuration<Content>) {

    self.configuration = configuration
    self.hostingController = .init(disableSafeArea: true, rootView: nil)
    super.init(frame: .zero)

    let hostingView = hostingController.view!

    addSubview(hostingView)
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingView.topAnchor.constraint(equalTo: topAnchor),
      hostingView.rightAnchor.constraint(equalTo: rightAnchor),
      hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
      hostingView.leftAnchor.constraint(equalTo: leftAnchor),
    ])

  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    super.sizeThatFits(size)
  }

  private func updateView(_ view: Content) {
    hostingController.rootView = view
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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

@available(iOS 13, *)
final class HostingController<Content: View>: UIHostingController<Content> {

  var onViewDidLayoutSubviews: (HostingController<Content>) -> Void = { _ in }

  init(disableSafeArea: Bool, rootView: Content) {
    super.init(rootView: rootView)

    _disableSafeArea = disableSafeArea

  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    //    onViewDidLayoutSubviews(self)
  }
}

extension UIResponder {

  func findNearestViewController() -> UIViewController? {
    sequence(first: self, next: { $0.next })
      .first {
        $0 is UIViewController
      } as? UIViewController
  }

}

// MARK: - Preview

#if DEBUG
struct BookVariadicView: View, PreviewProvider {
  var body: some View {

    NavigationView {
      List {

        NavigationLink {
          BackedContent()
            .navigationTitle("Backed")
        } label: {
          Text("Backed")
        }

        NavigationLink {
          NativeContent()
            .navigationTitle("Native")
        } label: {
          Text("Native")
        }

      }
    }


  }

  static var previews: some View {
    Self()
  }

  private struct NativeContent: View {

    @State var items: [Message] = MockData.randomMessages(count: 2000)

    var body: some View {
      VStack {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(items, content: {
              ComplexCell(message: $0)
            })
          }
        }
      }
    }
  }

  private struct BackedContent: View {

    @State var items: [Message] = MockData.randomMessages(count: 2000)

    var body: some View {
      VStack {
        CustomList {
          ForEach(items, content: {
            ComplexCell(message: $0)
          })
        }
      }
    }

    struct Cell1: View {

      @State var flag = false

      var body: some View {
        VStack {
          HStack {
            Text("Hello")
            Toggle("Flag", isOn: $flag)
          }
          Rectangle()
            .frame(height: flag ? 10 : 50)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
      }
    }

    struct Cell2: View {

      @State var flag = false

      var body: some View {
        VStack {
          HStack {
            Text("Hello")
            Toggle("Flag", isOn: $flag)
          }
          Rectangle()
            .fill(Color.red)
            .frame(height: flag ? 10 : 50)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
      }
    }

  }

  struct ComplexCell: View {

    let message: Message

    @State var count = 0

    var body: some View {

      HStack {
        Text(count.description)
        Text(message.text)

        HStack {
          Text(message.text)
          Text(message.text)
          Text(message.text)
          HStack {
            Text(message.text)
            Text(message.text)
            Text(message.text)
          }
        }
        .font(.system(size: 6))

      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.yellow)
      )
      .padding(8)
    }
  }

  struct Message: Identifiable {
    let id = UUID()
    var text: String
  }

  struct MockData {
    static let cannedText = [
      "Quisque maximus non est non condimentum.",
      "Praesent sit amet condimentum lacus, vel vehicula tellus. Cras non dolor vel nulla accumsan mollis.",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus risus libero, laoreet eget cursus vitae, malesuada quis magna. Sed tristique pharetra ultrices. Suspendisse vitae est quis leo auctor commodo eget vitae tortor. Sed convallis rutrum luctus. Fusce in nibh suscipit, venenatis est fringilla, sollicitudin mi.",
      "Aliquam euismod, tortor ut venenatis mattis, est neque rutrum massa, vitae laoreet nibh ex eu arcu. Curabitur ut augue in sem aliquam ultrices. Integer mollis mattis eros eget vulputate.",
      "Nam cursus semper lacinia. Nullam pretium massa auctor, vehicula augue ac, bibendum lorem.",
      "Hi",
    ]

    static func makeMessage() -> String {
      return cannedText.randomElement()!
    }

    static func randomMessages(count: Int) -> [Message] {
      var messages = [Message]()

      for _ in 0..<count {
        if let message = cannedText.randomElement() {
          messages.append(Message(text: message))
        }
      }
      return messages
    }
  }
}

#endif
