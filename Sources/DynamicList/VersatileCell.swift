import UIKit

public struct CellHighlightAnimationContext {
  public let cell: UICollectionViewCell
}

public protocol CellHighlightAnimation {

  @MainActor
  func onChange(isHighlighted: Bool, context: CellHighlightAnimationContext)
}

public struct DisabledCellHighlightAnimation: CellHighlightAnimation {

  public func onChange(isHighlighted: Bool, context: CellHighlightAnimationContext) {
    // no operation
  }
}

public struct ShrinkCellHighlightAnimation: CellHighlightAnimation {

  public func onChange(isHighlighted: Bool, context: CellHighlightAnimationContext) {

    let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)

    if isHighlighted {
      animator.addAnimations {
        context.cell.transform = .init(scaleX: 0.95, y: 0.95)
      }
    } else {
      animator.addAnimations {
        context.cell.transform = .identity
      }
    }
    animator.startAnimation()
  }
}

extension CellHighlightAnimation {

  public static func shrink(
    duration: TimeInterval = 0.4,
    dampingRatio: CGFloat = 1
  ) -> Self where Self == ShrinkCellHighlightAnimation {
    ShrinkCellHighlightAnimation()
  }

}

extension CellHighlightAnimation where Self == DisabledCellHighlightAnimation {
  public static var disabled: Self {
    DisabledCellHighlightAnimation()
  }
}

open class VersatileCell: UICollectionViewCell {

  open override var isHighlighted: Bool {
    didSet {
      guard oldValue != isHighlighted else { return }
      _highlightAnimation.onChange(isHighlighted: isHighlighted, context: .init(cell: self))
    }
  }

  public var _updateConfigurationHandler:
  @MainActor (_ cell: VersatileCell, _ state: UICellConfigurationState) -> Void = { _, _ in }

  private var _highlightAnimation: any CellHighlightAnimation = .disabled

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
    if #available(iOS 16, *) {
      // from iOS 16, auto-resizing runs
      super.invalidateIntrinsicContentSize()
    } else {
      super.invalidateIntrinsicContentSize()
      self.layoutWithInvalidatingCollectionViewLayout(animated: true)
    }
  }

  open override func updateConfiguration(using state: UICellConfigurationState) {
    super.updateConfiguration(using: state)
    _updateConfigurationHandler(self, state)
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
          collectionView.layoutIfNeeded()
          collectionView.collectionViewLayout.invalidateLayout()
        },
        completion: { (finish) in

        }
      )

    } else {

      CATransaction.begin()
      CATransaction.setDisableActions(true)
      collectionView.layoutIfNeeded()
      collectionView.collectionViewLayout.invalidateLayout()
      CATransaction.commit()

    }
  }

  public func highlightAnimation(_ animation: any CellHighlightAnimation) -> Self {
    self._highlightAnimation = animation
    return self
  }

}
