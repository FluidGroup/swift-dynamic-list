import IndexedCollection
import SwiftUI

public struct CollectionView<
  Content: View,
  Layout: CollectionViewLayoutType
>: View {

  public let content: Content

  public let layout: Layout

  public init(
    layout: Layout,
    @ViewBuilder content: () -> Content
  ) {
    self.layout = layout
    self.content = content()
  }

  public var body: some View {
    content
      .modifier(layout)
  }

}

#if canImport(ScrollTracking)

@_spi(Internal)
import ScrollTracking

extension CollectionView {
   
  @ViewBuilder
  public func onAdditionalLoading(
    isEnabled: Bool = true,
    leadingScreens: Double = 2,
    isLoading: Binding<Bool>,
    _ handler: @MainActor @escaping () async -> Void
  ) -> some View {
    
    self.onAdditionalLoading( 
      additionalLoading: .init(
        isEnabled: isEnabled,
        leadingScreens: leadingScreens,
        isLoading: isLoading,
        handler: handler
      )
    )
    
  }
  
}

#endif
