import Combine
import SwiftUI
import SwiftUIIntrospect
import os.lock

extension View {
  
  @_spi(Internal)
  public func onAdditionalLoading(
    additionalLoading: AdditionalLoading
  ) -> some View {
    
    modifier(
      _Modifier(
        additionalLoading: additionalLoading
      )
    )
    
  }
}

extension ScrollView {

  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor  () async -> Void
  ) -> some View {

    modifier(
      _Modifier(
        additionalLoading: .init(
          isEnabled: isEnabled,
          leadingScreens: leadingScreens,
          isLoading: isLoading,
          onLoad: onLoad
        )
      )
    )

  }

}

extension List {
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor  () async -> Void
  ) -> some View {
    
    modifier(
      _Modifier(
        additionalLoading: .init(
          isEnabled: isEnabled,
          leadingScreens: leadingScreens,
          isLoading: isLoading,
          onLoad: onLoad
        )
      )
    )
    
  }
}

public struct AdditionalLoading: Sendable {
  
  public let isEnabled: Bool
  public let leadingScreens: Double
  public let isLoading: Binding<Bool>
  public let onLoad: @MainActor () async -> Void

  public init(
    isEnabled: Bool,
    leadingScreens: Double,
    isLoading: Binding<Bool>,
    onLoad: @escaping @MainActor () async -> Void
  ) {
    self.isEnabled = isEnabled
    self.leadingScreens = leadingScreens
    self.isLoading = isLoading
    self.onLoad = onLoad
  }
  
}

@MainActor
private final class Controller: ObservableObject {
  
  var scrollViewSubscription: AnyCancellable? = nil
  var currentLoadingTask: Task<Void, Never>? = nil
  
  nonisolated init() {}
}

@available(iOS 15.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct _Modifier: ViewModifier {

  @StateObject var controller: Controller = .init()

  private let additionalLoading: AdditionalLoading

  nonisolated init(
    additionalLoading: AdditionalLoading
  ) {
    self.additionalLoading = additionalLoading
  }

  func body(content: Content) -> some View {

    if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
      content.onScrollGeometryChange(for: ScrollGeometry.self) { geometry in

        return geometry

      } action: { _, geometry in
        let triggers = calculate(
          contentOffsetY: geometry.contentOffset.y,
          boundsHeight: geometry.containerSize.height,
          contentSizeHeight: geometry.contentSize.height,
          leadingScreens: additionalLoading.leadingScreens
        )

        if triggers {
          MainActor.assumeIsolated {
            trigger()
          }
        }

      }
    } else {
      
      #if canImport(UIKit)

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
            leadingScreens: additionalLoading.leadingScreens
          )

          if triggers {
            trigger()
          }

        }
      }
      #else
      fatalError()
      #endif
    }
  }

  @MainActor
  private func trigger() {

    guard additionalLoading.isEnabled else {
      return
    }
    
    guard controller.currentLoadingTask == nil else {
      return
    }
    
    Task { @MainActor in    
      additionalLoading.isLoading.wrappedValue = true
    }
    
    let task = Task { @MainActor in
      await withTaskCancellationHandler {
        await additionalLoading.onLoad()
        Task { @MainActor in 
          additionalLoading.isLoading.wrappedValue = false
        }
        controller.currentLoadingTask = nil
      } onCancel: {
        Task { @MainActor in 
          additionalLoading.isLoading.wrappedValue = false
          controller.currentLoadingTask = nil
        }
      }
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

#Preview {
  
  List(0..<100) { index in
    Text("Item \(index)")
      .frame(height: 50)
      .background(Color.red)
  }
  .onAdditionalLoading(isLoading: .constant(true), onLoad: {
    print("Load more")
  })
  .onAppear {
    print("Hello")
  }
}

#Preview("ScrollView") {
  
  ScrollView {
    LazyVStack {
      ForEach(0..<100) { index in
        Text("Item \(index)")
          .frame(height: 50)
          .background(Color.red)
      }
    }
  }    
  .onAdditionalLoading(isLoading: .constant(true), onLoad: {
    print("Load more")
  })
  .onAppear {
    print("Hello")
  }
}
