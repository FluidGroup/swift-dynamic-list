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
