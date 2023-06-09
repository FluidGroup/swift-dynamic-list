import SwiftUI
import SwiftUIHosting
import SwiftUISupport
import UIKit

struct CustomList<Content: View>: View {

  let tree: _VariadicView.Tree<VariadicViewProxy, Content>

  init(@ViewBuilder content: () -> Content) {
    self.tree = _VariadicView.Tree(VariadicViewProxy(), content: content)
  }

  var body: some View {
    tree
  }

  struct VariadicViewProxy: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
      _CollectionView(children: children)
    }
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

  typealias View = DynamicCompositionalLayoutView<Int, ViewBox>

  private let views: [ViewBox]

  init(children: _VariadicView.Children) {
    // TODO: stop mapping. accessing directly.
    print(children.map { $0.id })
    self.views = children.map { ViewBox($0) }
  }

  func makeUIView(context: Context) -> View {

    let view = View(scrollDirection: .vertical)

    view.registerCell(DynamicSizingCollectionViewCell.self)
    view.setUp(
      cellProvider: { context in

        let cell = context.dequeueReusableCell(DynamicSizingCollectionViewCell.self)

        if #available(iOS 16, *) {

          cell.contentConfiguration = UIHostingConfiguration(content: {
            context.data.value
          })
          .margins(.all, 0)

        } else {
          cell.contentConfiguration = _Configuration(context.data.value)
        }

        return cell

      },
      actionHandler: { action in

      }
    )
    return view
  }

  func updateUIView(_ uiView: View, context: Context) {
    uiView.setContents(views, inSection: 0)
  }
}

class CollectionView: UICollectionView {

  override func layoutSubviews() {
    super.layoutSubviews()
  }

}

class _UICollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {

  override func invalidateLayout() {
    super.invalidateLayout()
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
    -> UICollectionViewLayoutAttributes?
  {
    super.layoutAttributesForItem(at: indexPath)
  }
}

// MARK: - Preview

#if DEBUG
struct BookVariadicView: View, PreviewProvider {
  var body: some View {

    NavigationView {
      List {

        NavigationLink {
          BackedContent()
            .navigationTitle("Backed")
        } label: {
          Text("Backed")
        }

        NavigationLink {
          NativeContent()
            .navigationTitle("Native")
        } label: {
          Text("Native")
        }

      }
    }


  }

  static var previews: some View {
    Self()
  }

  private struct NativeContent: View {

    @State var items: [Message] = MockData.randomMessages(count: 2000)

    var body: some View {
      VStack {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(items, content: {
              ComplexCell(message: $0)
            })
          }
        }
      }
    }
  }

  private struct BackedContent: View {

    @State var items: [Message] = MockData.randomMessages(count: 2000)

    var body: some View {
      VStack {
        CustomList {
          ForEach(items, content: {
            ComplexCell(message: $0)
          })
        }
      }
    }

    struct Cell1: View {

      @State var flag = false

      var body: some View {
        VStack {
          HStack {
            Text("Hello")
            Toggle("Flag", isOn: $flag)
          }
          Rectangle()
            .frame(height: flag ? 10 : 50)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
      }
    }

    struct Cell2: View {

      @State var flag = false

      var body: some View {
        VStack {
          HStack {
            Text("Hello")
            Toggle("Flag", isOn: $flag)
          }
          Rectangle()
            .fill(Color.red)
            .frame(height: flag ? 10 : 50)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
      }
    }

  }

  struct ComplexCell: View {

    let message: Message

    @State var count = 0

    var body: some View {

      HStack {
        Text(count.description)
        Text(message.text)

        HStack {
          Text(message.text)
          Text(message.text)
          Text(message.text)
          HStack {
            Text(message.text)
            Text(message.text)
            Text(message.text)
          }
        }
        .font(.system(size: 6))

      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.yellow)
      )
      .padding(8)
    }
  }

  struct Message: Identifiable {
    let id = UUID()
    var text: String
  }

  struct MockData {
    static let cannedText = [
      "Quisque maximus non est non condimentum.",
      "Praesent sit amet condimentum lacus, vel vehicula tellus. Cras non dolor vel nulla accumsan mollis.",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus risus libero, laoreet eget cursus vitae, malesuada quis magna. Sed tristique pharetra ultrices. Suspendisse vitae est quis leo auctor commodo eget vitae tortor. Sed convallis rutrum luctus. Fusce in nibh suscipit, venenatis est fringilla, sollicitudin mi.",
      "Aliquam euismod, tortor ut venenatis mattis, est neque rutrum massa, vitae laoreet nibh ex eu arcu. Curabitur ut augue in sem aliquam ultrices. Integer mollis mattis eros eget vulputate.",
      "Nam cursus semper lacinia. Nullam pretium massa auctor, vehicula augue ac, bibendum lorem.",
      "Hi",
    ]

    static func makeMessage() -> String {
      return cannedText.randomElement()!
    }

    static func randomMessages(count: Int) -> [Message] {
      var messages = [Message]()

      for _ in 0..<count {
        if let message = cannedText.randomElement() {
          messages.append(Message(text: message))
        }
      }
      return messages
    }
  }
}

#endif
