import UIKit

open class VersatileCell: UICollectionViewCell {

  let animator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1)

  open override var isHighlighted: Bool {
    didSet {
      guard oldValue != isHighlighted else { return }

      if isHighlighted {
        animator.addAnimations { [self] in
          transform = .init(scaleX: 0.95, y: 0.95)
        }
      } else {
        animator.addAnimations { [self] in
          transform = .identity
        }
      }
      animator.startAnimation()
    }
  }

  public var _updateConfigurationHandler:
  @MainActor (_ cell: VersatileCell, _ state: UICellConfigurationState) -> Void = { _, _ in }

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

}
