import SwiftUI
import IndexedCollection

public enum CollectionViewListDirection {
  case vertical
  case horizontal
}

/// A protocol that makes laid out contents of the collection view
public protocol CollectionViewLayoutType: ViewModifier {

}

public enum CollectionViewLayouts {

  public struct PlatformList: CollectionViewLayoutType {

    public init() {
    }

    public func body(content: Content) -> some View {
      SwiftUI.List {
        content
      }
    }
  }

  public struct PlatformListVanilla: CollectionViewLayoutType {

    public init() {
    }

    public func body(content: Content) -> some View {
      SwiftUI.List {
        content
          .listSectionSeparator(.hidden)
          .listRowSeparator(.hidden)
          .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
      }
      .listStyle(.plain)
    }
  }

  public struct List<Separator: View>: CollectionViewLayoutType {

    public let direction: CollectionViewListDirection

    public var showsIndicators: Bool = false

    public var contentPadding: EdgeInsets

    private let separator: Separator

    public init(
      direction: CollectionViewListDirection,
      contentPadding: EdgeInsets = .init(),
      @ViewBuilder separator: () -> Separator
    ) {
      self.direction = direction
      self.contentPadding = contentPadding
      self.separator = separator()
    }

    public init(
      direction: CollectionViewListDirection,
      contentPadding: EdgeInsets = .init()
    ) where Separator == EmptyView {
      self.direction = direction
      self.contentPadding = contentPadding
      self.separator = EmptyView()
    }

    public func separator<NewSeparator: View>(
      @ViewBuilder separator: () -> NewSeparator
    ) -> List<NewSeparator> {
      .init(
        direction: direction,
        contentPadding: contentPadding,
        separator: separator
      )
    }

    public consuming func contentPadding(_ contentPadding: EdgeInsets) -> Self {

      self.contentPadding = contentPadding

      return self
    }

    public consuming func showsIndicators(_ showsIndicators: Bool) -> Self {

      self.showsIndicators = showsIndicators

      return self
    }

    public func body(content: Content) -> some View {
      switch direction {
      case .vertical:

        ScrollView(.vertical, showsIndicators: showsIndicators) {

          if separator is EmptyView {
            LazyVStack {
              content
            }
            .padding(contentPadding)
          } else {
            UnaryViewReader(readingContent: content) { children in
              let last = children.last?.id
              LazyVStack {
                ForEach(children) { child in
                  child
                  if child.id != last {
                    separator
                      ._identified(by: "separator-\(child.id)")
                  }
                }
              }
            }
            .padding(contentPadding)
          }
        }

      case .horizontal:

        ScrollView(.horizontal, showsIndicators: showsIndicators) {

          if separator is EmptyView {
            LazyHStack {
              content
            }
            .padding(contentPadding)

          } else {

            UnaryViewReader(readingContent: content) { children in
              let last = children.last?.id
              LazyHStack {
                ForEach(children) { child in
                  child
                  if child.id != last {
                    separator
                      ._identified(by: "separator-\(child.id)")
                  }
                }
              }
            }
            .padding(contentPadding)
          }
        }

      }
    }

  }

  public struct Grid: CollectionViewLayoutType {
    
    public let gridItems: [GridItem]

    public let direction: CollectionViewListDirection

    public var showsIndicators: Bool = false
    
    public var contentPadding: EdgeInsets

    public var spacing: CGFloat?
    
    public init(
      gridItems: [GridItem],
      direction: CollectionViewListDirection,
      spacing: CGFloat? = nil,
      contentPadding: EdgeInsets = .init()
    ) {
      self.direction = direction
      self.contentPadding = contentPadding
      self.gridItems = gridItems
      self.spacing = spacing
      self.contentPadding = contentPadding
    }

    public consuming func contentPadding(_ contentPadding: EdgeInsets) -> Self {
      
      self.contentPadding = contentPadding
      
      return self
    }
    
    public consuming func showsIndicators(_ showsIndicators: Bool) -> Self {
      
      self.showsIndicators = showsIndicators
      
      return self
    }
    
    public func body(content: Content) -> some View {
      switch direction {
      case .vertical:
        
        ScrollView(.vertical, showsIndicators: showsIndicators) {
          LazyVGrid(
            columns: gridItems,
            spacing: spacing
          ) {
            content
          }          
          .padding(contentPadding)
        }
        
      case .horizontal:
        
        ScrollView(.horizontal, showsIndicators: showsIndicators) {          
          LazyHGrid(
            rows: gridItems,
            spacing: spacing
          ) {
            content
          }
          .padding(contentPadding)
        }
        
      }
    }

  }

  public struct FastGrid: CollectionViewLayoutType {

    public var showsIndicators: Bool = false

    public var contentPadding: EdgeInsets

    public var spacing: CGFloat?

    public let height: CGFloat?

    public init(
      spacing: CGFloat? = nil,
      height: CGFloat? = nil,
      contentPadding: EdgeInsets = .init()
    ) {
      self.contentPadding = contentPadding
      self.height = height
      self.spacing = spacing
    }

    public consuming func contentPadding(_ contentPadding: EdgeInsets) -> Self {

      self.contentPadding = contentPadding

      return self
    }

    public consuming func showsIndicators(_ showsIndicators: Bool) -> Self {

      self.showsIndicators = showsIndicators

      return self
    }

    public func body(content: Content) -> some View {

      ScrollView(.vertical, showsIndicators: showsIndicators) {
        UnaryViewReader(readingContent: content) { children in
          let indices = children.indices

          LazyVStack {

            ForEach(IndexedCollection(children), id: \.id) { e in

              let (index, child) = (e.index, e.value)

              if index % 3 == 0 {

                let first = child
                let second = indices.contains(index + 1) ? children[index + 1] : nil
                let third = indices.contains(index + 2) ? children[index + 2] : nil

                HStack {
                  first
                    .layoutPriority(1)

                  if let second = second {
                    second
                      .layoutPriority(1)
                  } else {
                    Spacer()
                      .layoutPriority(1)
                  }
                  if let third = third {
                    third
                      .layoutPriority(1)
                  } else {
                    Spacer()
                      .layoutPriority(1)
                  }
                }
                .frame(height: height)

              } else {
                EmptyView()
              }
            }
          }
        }
        .padding(contentPadding)
      }


    }

  }

}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.List<EmptyView> {

  public static var list: Self {
    CollectionViewLayouts.List(
      direction: .vertical
    )
  }

}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.Grid {

  public static func grid(
    gridItems: [GridItem],
    direction: CollectionViewListDirection,
    spacing: CGFloat? = nil
  ) -> Self {
    CollectionViewLayouts.Grid(
      gridItems: gridItems,
      direction: direction,
      spacing: spacing
    )
  }

}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.FastGrid {

  public static func fastGrid(
    spacing: CGFloat?,
    height: CGFloat?
  ) -> Self {
    CollectionViewLayouts.FastGrid(spacing: spacing, height: height)
  }

}

