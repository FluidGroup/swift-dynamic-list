import Combine
import SwiftUI
import SwiftUIIntrospect

extension ScrollView {

  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: CGFloat = 2,
    _ handler: @MainActor @escaping () async -> Void
  ) -> some View {

    modifier(
      _Modifier(
        isEnabled: isEnabled,
        leadingScreens: leadingScreens,
        handler: handler
      )
    )

  }

}

private final class Controller: ObservableObject {
  var scrollViewSubscription: AnyCancellable?
  var currentLoadingTask: Task<Void, Never>?
}

private struct _Modifier: ViewModifier {

  @StateObject var controller: Controller = .init()

  private let isEnabled: Bool
  private let leadingScreens: CGFloat
  private let handler: @MainActor () async -> Void

  nonisolated init(
    isEnabled: Bool,
    leadingScreens: CGFloat,
    handler: @MainActor @escaping () async -> Void
  ) {
    self.isEnabled = isEnabled
    self.leadingScreens = leadingScreens
    self.handler = handler
  }

  func body(content: Content) -> some View {

    if #available(iOS 18, *) {
      content.onScrollGeometryChange(for: Bool.self) { geometry in

        return calculate(
          contentOffsetY: geometry.contentOffset.y,
          boundsHeight: geometry.containerSize.height,
          contentSizeHeight: geometry.contentSize.height,
          leadingScreens: leadingScreens
        )

      } action: { oldValue, newValue in

        if newValue {
          MainActor.assumeIsolated {
            trigger()
          }
        }

      }
    } else {

      content.introspect(.scrollView, on: .iOS(.v15, .v16, .v17)) { scrollView in

        controller.scrollViewSubscription?.cancel()

        controller.scrollViewSubscription = scrollView.publisher(for: \.contentOffset).sink {
          [weak scrollView] offset in

          guard let scrollView else {
            return
          }

          let triggers = calculate(
            contentOffsetY: offset.y,
            boundsHeight: scrollView.bounds.height,
            contentSizeHeight: scrollView.contentSize.height,
            leadingScreens: leadingScreens
          )

          if triggers {
            trigger()        
          }

        }
      }
    }
  }

  private func trigger() {

    guard isEnabled else {
      return
    }

    guard controller.currentLoadingTask == nil else {
      return
    }

    let task = Task { @MainActor [weak controller] in
      await handler()
      controller?.currentLoadingTask = nil
    }

    controller.currentLoadingTask = task
  }

}

private func calculate(
  contentOffsetY: CGFloat,
  boundsHeight: CGFloat,
  contentSizeHeight: CGFloat,
  leadingScreens: CGFloat
) -> Bool {

  guard leadingScreens > 0 || boundsHeight != .zero else {
    return false
  }

  let viewLength = boundsHeight
  let offset = contentOffsetY
  let contentLength = contentSizeHeight

  let hasSmallContent = (offset == 0.0) && (contentLength < viewLength)

  let triggerDistance = viewLength * leadingScreens
  let remainingDistance = contentLength - viewLength - offset

  return (hasSmallContent || remainingDistance <= triggerDistance)
}
