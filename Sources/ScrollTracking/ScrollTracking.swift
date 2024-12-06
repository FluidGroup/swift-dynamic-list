import Combine
import SwiftUI
import SwiftUIIntrospect
import os.lock

extension ScrollView {

  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: CGFloat = 2,
    isLoading: Binding<Bool>,
    _ handler: @MainActor @escaping () async -> Void
  ) -> some View {

    modifier(
      _Modifier(
        isEnabled: isEnabled,
        leadingScreens: leadingScreens, 
        isLoading: isLoading,
        handler: handler
      )
    )

  }

}

private final class Controller: ObservableObject {
  var scrollViewSubscription: AnyCancellable?
  let currentLoadingTask: OSAllocatedUnfairLock<Task<Void, Never>?> = .init(initialState: nil)
}

private struct _Modifier: ViewModifier {

  @StateObject var controller: Controller = .init()

  private let isEnabled: Bool
  private let leadingScreens: CGFloat
  private let isLoading: Binding<Bool>
  private let handler: @MainActor () async -> Void

  nonisolated init(
    isEnabled: Bool,
    leadingScreens: CGFloat,
    isLoading: Binding<Bool>,
    handler: @MainActor @escaping () async -> Void
  ) {
    self.isEnabled = isEnabled
    self.isLoading = isLoading
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
    
    let taskBox = controller.currentLoadingTask

    taskBox.withLockUnchecked { currentTask in
      
      guard currentTask == nil else {
        return 
      }
      
      isLoading.wrappedValue = true
            
      let task = Task { @MainActor in
        await withTaskCancellationHandler { 
          await handler()
          isLoading.wrappedValue = false
          taskBox.withLock { $0 = nil }
        } onCancel: { 
          isLoading.wrappedValue = false
          taskBox.withLock { $0 = nil }
        }    
      }
      
      currentTask = task
      
    }  
  
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
