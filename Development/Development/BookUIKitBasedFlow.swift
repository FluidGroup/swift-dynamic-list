import SwiftUI
import UIKit
import DynamicList
import os


nonisolated(unsafe) fileprivate var globalCount: Int = 0
fileprivate func getGlobalCount() -> Int {
  globalCount &+= 1
  return globalCount
}


struct BookUIKitBasedFlow: View, PreviewProvider {
  var body: some View {
    Content()
  }

  static var previews: some View {
    Self()
  }

  private struct Content: View {

    var body: some View {
      _View()
    }
  }

  private struct _View: UIViewRepresentable {

    func makeUIView(context: Context) -> ContainerView {
      ContainerView()
    }

    func updateUIView(_ uiView: BookUIKitBasedFlow.ContainerView, context: Context) {

    }
  }

  enum Block: Hashable {
    case a(A)
    case b(B)

    struct A: Hashable {
      let id: Int = getGlobalCount()
      let name: String
      let introduction: String = random(count: (1..<5).randomElement()!)
    }

    struct B: Hashable {
      let id: Int = getGlobalCount()
      let name: String
      let introduction: String = random(count: (1..<5).randomElement()!)
    }
  }


  private final class ContainerView: UIView {

    private let list = DynamicListView<Int, Block>(
      layout: {

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        return flowLayout
      }(),
      scrollDirection: .vertical
    )

    //    private let list = DynamicCompositionalLayoutView<Int, Block>(scrollDirection: .vertical)

    private var currentData = (0..<50).flatMap { i in
      [
        Block.a(.init(name: "\(i)")),
        Block.b(.init(name: "\(i)")),
      ]
    }

    init() {
      super.init(frame: .null)

      addSubview(list)
      list.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activate([
        list.topAnchor.constraint(equalTo: topAnchor),
        list.bottomAnchor.constraint(equalTo: bottomAnchor),
        list.leadingAnchor.constraint(equalTo: leadingAnchor),
        list.trailingAnchor.constraint(equalTo: trailingAnchor),
      ])

      list.setUp(
        cellProvider: { context in

          switch context.data {
          case .a(let v):
            return context.cell(reuseIdentifier: "A") { state, _ in
              ComposableCell {
                TextField("Hello", text: .constant("Hoge"))
                HStack {
                  Text("\(state.isHighlighted.description)")
                  Text("\(v.name)")
                    .redacted(reason: .placeholder)
                  Text("\(v.introduction)")
                    .redacted(reason: .placeholder)
                }
              }
              .onAppear {
                print("OnAppear", v.id)
              }
            }
          case .b(let v):
            return context.cell(reuseIdentifier: "B") { _, _ in
              Button {

              } label: {
                VStack {
                  Button("Action") {
                    print("Action")
                  }
                  Text("\(v.name)")
                    .foregroundColor(Color.green)
                    .redacted(reason: .placeholder)

                  Text("\(v.introduction)")
                    .foregroundColor(Color.green)
                    .redacted(reason: .placeholder)
                }
              }
              .background(Color.red)

            }
          }

        }
      )

      list.setIncrementalContentLoader { [weak list, weak self] in
        guard let self else { return }
        guard let list else { return }

        self.currentData.append(
          contentsOf: (0..<50).flatMap { i in
            [
              Block.a(.init(name: "\(i)")),
              Block.b(.init(name: "\(i)")),
            ]
          }
        )
        list.setContents(self.currentData, inSection: 0)
      }

      list.setSelectionHandler { action in
        switch action {
        case .didSelect(let item):
          print("Selected \(String(describing: item))")
        case .didDeselect(let item):
          print("Deselected \(String(describing: item))")
        }
      }

      list.setContents(currentData, inSection: 0)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

  }

  private struct ComposableCell<Content: View>: View {

    @State var flag = false
    @Environment(\.versatileCell) var cell

    private let content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
      self.content = content()
    }

    var body: some View {

      VStack {

        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .frame(height: flag ? 60 : 120)
          .foregroundColor(Color.purple.opacity(0.2))
          .overlay(Button("Toggle") {
            flag.toggle()
            DispatchQueue.main.async {
              cell?.invalidateIntrinsicContentSize()
            }
          })

        content
          .padding(16)
          .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.green.opacity(0.2)))
      }

    }

  }
}

private final class _UICollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {

  override func invalidateLayout() {
    super.invalidateLayout()
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
  -> UICollectionViewLayoutAttributes?
  {
    super.layoutAttributesForItem(at: indexPath)
  }

  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    super.invalidateLayout(with: context)
  }
}

fileprivate func random(count: Int) -> String {

  let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

  // Split the lorem ipsum text into words
  let words = loremIpsum.components(separatedBy: " ")

  // Generate a random text with 10 words
  var randomText = ""
  for _ in 0..<count {
    if let randomWord = words.randomElement() {
      randomText += randomWord + " "
    }
  }

  return randomText
}

