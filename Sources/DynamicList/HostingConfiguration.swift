#if canImport(UIKit)
import UIKit
import SwiftUI

public struct HostingConfiguration<Content: View>: UIContentConfiguration {

  public let content: Content

  public init(@ViewBuilder _ content: () -> Content) {
    self.content = content()
  }

  public init(_ content: Content) {
    self.content = content
  }

  public func makeContentView() -> UIView & UIContentView {
    let content = _ContentView(configuration: self)
    content.configuration = self
    return content
  }

  public func updated(for state: UIConfigurationState) -> HostingConfiguration {
    return self
  }

  private final class _ContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
      didSet {
        // FIXME: assume the type will be mismatched if the content is dynamic.
        let configuration = configuration as! HostingConfiguration<Content>
        updateView(configuration.content)
      }
    }

    private let hostingController: HostingController<Content?>

    init(configuration: HostingConfiguration<Content>) {

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

    override func didMoveToSuperview() {
      if superview == nil {
        hostingController.willMove(toParent: nil)
        hostingController.removeFromParent()
      } else {
        parentViewController?.addChild(hostingController)
        hostingController.didMove(toParent: parentViewController)
      }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

  }
}

@available(iOS 13, *)
private final class HostingController<Content: View>: UIHostingController<Content> {

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

private extension UIResponder {
  var parentViewController: UIViewController? {
    return next as? UIViewController ?? next?.parentViewController
  }
}
#endif
