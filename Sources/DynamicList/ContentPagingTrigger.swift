import UIKit

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
