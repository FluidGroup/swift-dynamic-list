
#if canImport(UIKit)
import UIKit

public struct CustomContentConfiguration<ContentView: UIView & UIContentView>: UIContentConfiguration {

  private let contentViewFactory: @MainActor () -> ContentView

  public init(make: @escaping @MainActor () -> ContentView) {
    self.contentViewFactory = make
  }

  public func makeContentView() -> UIView & UIContentView {
    contentViewFactory()
  }
  
  public func updated(for state: UIConfigurationState) -> CustomContentConfiguration<ContentView> {

    return self

  }

}
#endif
