import SwiftUI

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

  public struct List: CollectionViewLayoutType {

    public let direction: CollectionViewListDirection

    public var showsIndicators: Bool = false

    public var contentPadding: EdgeInsets



    public init(
      direction: CollectionViewListDirection,
      contentPadding: EdgeInsets = .init()
    ) {
      self.direction = direction
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

          LazyVStack {
            content
          }
          .padding(contentPadding)
        }

      case .horizontal:

        ScrollView(.horizontal, showsIndicators: showsIndicators) {

          LazyHStack {
            content
          }
          .padding(contentPadding)
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

}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.List {

  public static var list: Self {
    CollectionViewLayouts.List(
      direction: .vertical
    )
  }

}

extension CollectionViewLayoutType {

  public static func grid(
    gridItems: [GridItem],
    direction: CollectionViewListDirection,
    spacing: CGFloat? = nil
  ) -> Self where Self == CollectionViewLayouts.Grid {
    CollectionViewLayouts.Grid(
      gridItems: gridItems,
      direction: direction,
      spacing: spacing
    )
  }

}
