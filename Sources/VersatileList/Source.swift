import SwiftUI

public enum VersatileListDirection {
  case vertical
  case horizontal
}

/**
 Still searching better name
 - built on top of SwiftUI only
 */
@available(iOS 16, *)
public struct VersatileList<Data: Identifiable, Cell: View>: View {
  
  public let direction: VersatileListDirection
  
  private let cell: (Data) -> Cell
  
  public init(
    direction: VersatileListDirection,
    @ViewBuilder cell: @escaping (Data) -> Cell
  ) {
    
    self.direction = direction
    self.cell = cell
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
