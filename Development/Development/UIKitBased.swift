import SwiftUI
import UIKit
import swift_dynamic_list
import os

let debug = OSLog(subsystem: "D", category: .dynamicStackTracing)

let log = Logger(subsystem: "Demo", category: "Default")

struct BookUIKitBased: View, PreviewProvider {
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

    func updateUIView(_ uiView: BookUIKitBased.ContainerView, context: Context) {

    }
  }

  enum Block: Hashable {
    case a(A)
    case b(B)

    struct A: Hashable {
      let id: UUID = UUID()
      let name: String
      let introduction: String = random(count: (2..<20).randomElement()!)
    }

    struct B: Hashable {
      let id: UUID = UUID()
      let name: String
      let introduction: String = random(count: (2..<20).randomElement()!)
    }
  }


  private final class ContainerView: UIView {

    private let list = DynamicCompositionalLayoutView<Int, Block>(
      layout: {
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

        // Create a compositional layout using the defined section
        let layout = UICollectionViewCompositionalLayout(section: section)

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

          let cell = context.dequeueDefaultCell()

          switch context.data {
          case .a(let v):
            cell.setSwiftUIContent {
              HStack {
                Text("\(v.name)")
                  .redacted(reason: .placeholder)
                Text("\(v.introduction)")
                  .redacted(reason: .placeholder)
              }
              .padding(16)
              .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.green.opacity(0.2)))
            }
          case .b(let v):
            cell.setSwiftUIContent {
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
//                ._onButtonGesture(pressing: { isPressing in
//                  print("Pressing \(isPressing)")
//                  
//                }, perform: {
//                  print("Pressed")
//                  
//                })
              }

            }
          }

          return cell
        },
        actionHandler: { [weak self] list, action in
          guard let self else { return }
          switch action {
          case .batchFetch(let work):
            work {
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
          case .didSelect(let item):
            print("Selected \(String(describing: item))")
            break
          }
        }
      )

      list.setContents(currentData, inSection: 0)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

  }
}

func random(count: Int) -> String {

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
