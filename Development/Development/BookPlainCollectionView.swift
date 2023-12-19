import SwiftUI
import UIKit
import DynamicList
import MondrianLayout

struct BookPlainCollectionView: View, PreviewProvider {
  var body: some View {
    ContentView()
  }

  static var previews: some View {
    Self()
  }

  private struct ContentView: View {

    var body: some View {
      _View()
    }
  }

  private struct _View: UIViewRepresentable {

    func makeUIView(context: Context) -> ContainerView {
      ContainerView(frame: .zero)
    }

    func updateUIView(_ uiView: ContainerView, context: Context) {

    }
  }

  private final class ContainerView: UIView, UICollectionViewDataSource {

    private final class CustomCellContent: UIView, UIContentView {

      private let mark: UIView = .init()
      private let mark2: UIView = .init()
      private let label: UILabel = .init()

      var configuration: UIContentConfiguration {
        didSet {
          print("update configuration \(configuration)")
          update(with: configuration as! BookPlainCollectionView.ContainerView.CustomCellConfiguration)
        }
      }

      init(configuration: CustomCellConfiguration) {

        print(#function)

        self.configuration = configuration
        super.init(frame: .zero)

        mark.backgroundColor = UIColor.systemPurple
        mark.backgroundColor = UIColor.systemRed

        Mondrian.buildSubviews(on: self) {

          HStackBlock {
            VStackBlock {
              mark
                .viewBlock.size(width: 20, height: 20)
              mark2
                .viewBlock.size(width: 20, height: 20)
            }
            VStackBlock {
              label
                .viewBlock.padding(20)
            }
          }
        }

        update(with: configuration)
      }

      private func update(with configuration: CustomCellConfiguration) {

        label.text = configuration.text
        mark.isHidden = configuration.isSelected == false
        mark2.isHidden = configuration.isArchived == false
      }

      required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }
      
    }

    private struct CustomCellConfiguration: UIContentConfiguration {

      var text: String = ""
      var isSelected: Bool = false
      var isArchived: Bool = false

      public func makeContentView() -> UIView & UIContentView {
        let content = CustomCellContent(configuration: self)
        content.configuration = self
        return content
      }

      public func updated(for state: UIConfigurationState) -> Self {
        guard let cellState = state as? UICellConfigurationState else {
          assertionFailure()
          return self
        }
        print(cellState.isArchived)
        var new = self
        new.isSelected = cellState.isSelected
        new.isArchived = cellState.isArchived
        return new
      }

    }

    private var items: [Int] = (0..<100).map { $0 }

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain)))

    private let cellRegistration = UICollectionView.CellRegistration<VersatileCell, Int> { cell, indexPath, item in

      var contentConfiguration = CustomCellConfiguration()

      contentConfiguration.text = "\(item)"
//      contentConfiguration.textProperties.color = .lightGray

      cell.contentConfiguration = contentConfiguration
    }

    override init(frame: CGRect) {
      super.init(frame: frame)

      let actionButton = UIButton(primaryAction: .init(title: "Action", handler: { [weak self] _ in

        guard let self else { return }

        print(collectionView.cellForItem(at: .init(item: 99, section: 0)))

//        if #available(iOS 15.0, *) {
//          collectionView.reconfigureItems(at: collectionView.indexPathsForVisibleItems)
//        } else {
//          // Fallback on earlier versions
//        }

      }))

      Mondrian.buildSubviews(on: self) {
        VStackBlock {
          actionButton
          collectionView
        }
      }


      collectionView.dataSource = self

    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

      let item = items[indexPath.item]

      let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)

      return cell
    }

  }

}

extension UIConfigurationStateCustomKey {
  static let isArchived = UIConfigurationStateCustomKey("com.my-app.MyCell.isArchived")
}

extension UICellConfigurationState {
  var isArchived: Bool {
    get { return self[.isArchived] as? Bool ?? false }
    set { self[.isArchived] = newValue }
  }
}
