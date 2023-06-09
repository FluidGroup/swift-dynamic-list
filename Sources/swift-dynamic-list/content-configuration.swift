import UIKit
import SwiftUI

struct _Configuration<Content: View>: UIContentConfiguration {

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
