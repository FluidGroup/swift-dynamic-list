import IndexedCollection
import SwiftUI

public struct CollectionView<
  Content: View,
  Layout: CollectionViewLayoutType
>: View {

  private let content: Content

  private let layout: Layout

  public init(
    @ViewBuilder content: () -> Content,
    layout: Layout
  ) {
    self.content = content()
    self.layout = layout
  }

  public var body: some View {
    content
      .modifier(layout)
  }

}
