import SwiftUI
import UIKit
import DynamicList
import os
import MondrianLayout


nonisolated(unsafe) fileprivate var globalCount: Int = 0

fileprivate func getGlobalCount() -> Int {
  globalCount &+= 1
  return globalCount
}

enum IsArchivedKey: CustomStateKey {
  typealias Value = Bool

  static var defaultValue: Bool { false }
}

extension CellState {
  var isArchived: Bool {
    get { self[IsArchivedKey.self] }
    set { self[IsArchivedKey.self] = newValue }
  }
}

struct BookUIKitBasedCompositional: View, PreviewProvider {
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

    func updateUIView(_ uiView: BookUIKitBasedCompositional.ContainerView, context: Context) {

    }
  }

  enum Block: Hashable {
    case a(A)
    case b(B)

    struct A: Hashable {
      let id: Int = getGlobalCount()
      let name: String
      let introduction: String = random(count: (2..<20).randomElement()!)
    }

    struct B: Hashable {
      let id: Int = getGlobalCount()
      let name: String
      let introduction: String = random(count: (2..<20).randomElement()!)
    }
  }


  private final class ContainerView: UIView {

    private let list = DynamicListView<Int, Block>(
      compositionalLayout: {
        // Define the size of each item in the grid
        let itemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(0.25),
          heightDimension: .estimated(100)
        )

        // Create an item using the defined size
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // Define the group size as 4 items across and 4 items down
        let groupSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(100)
        )

        // Create a group using the defined group size and item
        let group = NSCollectionLayoutGroup.horizontal(
          layoutSize: groupSize,
          subitem: item,
          count: 2
        )

        // Create a section using the defined group
        let section = NSCollectionLayoutSection(group: group)

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
//        configuration.boundarySupplementaryItems = [
//          .init(
//            layoutSize: .init(
//              widthDimension: .fractionalWidth(1),
//              heightDimension: .estimated(100)
//            ),
//            elementKind: "Header",
//            alignment: .top
//          ),
//        ]

        // Create a compositional layout using the defined section
        let layout = _UICollectionViewCompositionalLayout(section: section, configuration: configuration)

        return layout
      }()
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

      let actionButton = UIButton(primaryAction: .init(title: "Action", handler: { [unowned self] _ in

        let target = currentData[49]

        if #available(iOS 15.0, *) {

          let current = list.state(for: target, key: IsArchivedKey.self) ?? false

          list.setState(!current, key: IsArchivedKey.self, for: target)
        } else {
          // Fallback on earlier versions
        }

      }))

      Mondrian.buildSubviews(on: self) {
        VStackBlock {
          actionButton
          list
        }
      }

      list.setUp(
        cellProvider: { context in

          switch context.data {
          case .a(let v):
            return context.cell(reuseIdentifier: "A") { state, customState in
              ComposableCell {
                HStack {
                  Text("\(state.isHighlighted.description)")
                  Text("\(v.name)")
                    .redacted(reason: .placeholder)
                  Text("\(v.introduction)")
                    .redacted(reason: .placeholder)
                }
              }
              .overlay(Color.red.opacity(0.8).opacity(customState.isArchived ? 1 : 0))
              .onAppear {
                print("OnAppear", v.id)
              }
            }
          case .b(let v):
            return context.cell(reuseIdentifier: "B") { _, customState in
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
              .overlay(Color.red.opacity(0.8).opacity(customState.isArchived ? 1 : 0))

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
