import SwiftUI

public enum VersatileListDirection {
  case vertical
  case horizontal
}

/**
 
 */
public struct VersatileList: View {
  
  public init(
    direction: VersatileListDirection
  ) {
    
  }
  
  public var body: some View {
    
    ScrollView(.vertical) { 
      
    }
    
  }
}
