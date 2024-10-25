import SwiftUI

public enum VersatileListDirection {
  case vertical
  case horizontal
}

public enum ListLayout {
  case list
}

/**
 Still searching better name
 - built on top of SwiftUI only
 */
@available(iOS 16, *)
public struct CollectionView<Data: Identifiable, Cell: View, Separator: View>: View {
  
  public let direction: VersatileListDirection
  
  private let cell: (Data) -> Cell
  private let separator: () -> Separator
  
  public init(
    direction: VersatileListDirection,
    @ViewBuilder cell: @escaping (Data) -> Cell,
    @ViewBuilder separator: @escaping () -> Separator
  ) {
    
    self.direction = direction
    self.cell = cell
    self.separator = separator
  }
  
  public var body: some View {
    
    // for now, switching verbose way
    
    switch direction {
    case .vertical:
      
      ScrollView(.vertical) { 
        LazyVStack {

        }
      }
      
    case .horizontal:
      
      ScrollView(.horizontal) { 
        LazyHStack {
          
        }
      }
      
    }
        
  }
}


#if DEBUG

private struct Item: Identifiable {
  var id: Int
  var title: String
}

#Preview {
  
  
}

#endif
