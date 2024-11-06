import SwiftUI

public enum CollectionViewListDirection {
  case vertical
  case horizontal
}

/**
 A protocol that makes laid out contents of the collection view
 */
public protocol CollectionViewLayoutType: ViewModifier {
  
}

public enum CollectionViewLayouts {
  
  public struct PlatformList: CollectionViewLayoutType {
    
    public func body(content: Content) -> some View {
      SwiftUI.List {
        content
      }
    }
  }
  
  public struct List<Separator: View>: CollectionViewLayoutType {
    
    public let direction: CollectionViewListDirection
    public let contentPadding: EdgeInsets
    
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
    
    public func body(content: Content) -> some View {
      switch direction {
      case .vertical:
        
        ScrollView(.vertical) {
          LazyVStack {
            VariadicViewReader(readingContent: content) { children in
              let last = children.last?.id
              ForEach(children) { child in 
                child
                if child.id != last {
                  separator
                }
              }              
            }
          }
          .padding(contentPadding)
        }
        
      case .horizontal:
        
        ScrollView(.horizontal) {
          LazyHStack {
            VariadicViewReader(readingContent: content) { children in
              let last = children.last?.id
              ForEach(children) { child in 
                child
                if child.id != last {
                  separator
                }
              }  
            }
          }
          .padding(contentPadding)
        }
        
      }
    }
    
  }
  
  public struct Grid: CollectionViewLayoutType {
    
    public func body(content: Content) -> some View {
      // FIXME:
    }
  }
  
}

extension CollectionViewLayoutType where Self == CollectionViewLayouts.List<EmptyView> {
  
  public static var list: Self {
    CollectionViewLayouts.List(
      direction: .vertical,
      separator: { EmptyView() }
    )
  }
  
}

extension CollectionViewLayoutType {
  
  public static func list<Separator: View>(
    @ViewBuilder separator: () -> Separator
  ) -> Self where Self == CollectionViewLayouts.List<Separator> {
    .init(direction: .vertical, separator: separator)
  }
  
}


extension CollectionViewLayoutType where Self == CollectionViewLayouts.Grid {
  
  public static var grid: Self {
    CollectionViewLayouts.Grid()
  }
  
}
