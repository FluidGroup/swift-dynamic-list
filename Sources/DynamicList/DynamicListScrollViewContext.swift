import UIKit

public struct DynamicListScrollViewContext: Equatable {

  public let contentOffset: CGPoint
  public let contentInset: UIEdgeInsets
  public let adjustedContentInset: UIEdgeInsets

  init(scrollView: UIScrollView) {
    self.contentOffset = scrollView.contentOffset
    self.contentInset = scrollView.contentInset
    self.adjustedContentInset = scrollView.adjustedContentInset
  }
}
