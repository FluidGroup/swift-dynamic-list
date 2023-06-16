import SwiftUI
import SwiftUISupport
import UIKit

#if DEBUG
public struct CustomList<Content: View>: View {

  let tree: _VariadicView.Tree<VariadicViewProxy, Content>

  public init(@ViewBuilder content: () -> Content) {
    self.tree = _VariadicView.Tree(VariadicViewProxy(), content: content)
  }

  public var body: some View {
    tree
  }

  struct VariadicViewProxy: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
      _CollectionView(children: children)
    }
  }

}

extension _VariadicView_Children.Element: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    id.hash(into: &hasher)
  }
}

struct _CollectionView: UIViewRepresentable {

  struct ViewBox: Hashable {

    static func == (lhs: ViewBox, rhs: ViewBox) -> Bool {
      lhs.value.id == rhs.value.id
    }

    let value: _VariadicView.Children.Element

    func hash(into hasher: inout Hasher) {
      value.id.hash(into: &hasher)
    }

    init(_ value: _VariadicView.Children.Element) {
      self.value = value
    }

  }

  typealias View = DynamicListView<Int, _VariadicView_Children.Element>

  private let children: _VariadicView.Children

  init(children: _VariadicView.Children) {
    self.children = children
  }

  func makeUIView(context: Context) -> View {

    let view = View(scrollDirection: .vertical)

    view.registerCell(VersatileCell.self)
    view.setUp(
      cellProvider: { context in

        let cell = context.dequeueReusableCell(VersatileCell.self)

        if #available(iOS 16, *) {

          cell.contentConfiguration = UIHostingConfiguration(content: {
            context.data.id(context.data.id)
          })
          .margins(.all, 0)

        } else {
          cell.contentConfiguration = HostingConfiguration(context.data)
        }

        return cell

      }
    )
    return view
  }

  func updateUIView(_ uiView: View, context: Context) {
    uiView.setContents(Array(children), inSection: 0)
  }
}

#endif
