import SwiftUI

/** 
 A view that sticks to the top of the screen in a ScrollView.
 When it's bouncing, it stretches the content.
 To use this view, you need to call ``View.enableStickyHeader()`` modifier to the ScrollView. 
 */
public struct StickyHeader<Content: View>: View {

  /**
   The option to determine how to size the header.
   */
  public enum Sizing {
    /// Uses the given content's intrinsic size.
    case content
    /// Uses the fixed height.
    case fixed(CGFloat)
  }

  public let sizing: Sizing
  public let content: Content

  @State var baseContentHeight: CGFloat?
  @State var stretchingValue: CGFloat = 0

  public init(
    sizing: Sizing,
    @ViewBuilder content: () -> Content
  ) {
    self.sizing = sizing
    self.content = content()
  }

  public var body: some View {
    
    let offsetY: CGFloat = 0
    
    Group {
      switch sizing {
      case .content:
        content
          .onGeometryChange(for: CGSize.self, of: \.size) { size in
            if stretchingValue == 0 {
              baseContentHeight = size.height
            }
          }
          .frame(height: baseContentHeight.map { 
            $0 + stretchingValue
          })
          .offset(y: -stretchingValue)
        // container
          .frame(height: baseContentHeight, alignment: .top)

      case .fixed(let height):
                       
        content
          .frame(height: height + stretchingValue + offsetY)
          .offset(y: -offsetY)
          .offset(y: -stretchingValue)
        // container
          .frame(height: height, alignment: .top)
      }
    }   
    .onGeometryChange(
      for: CGRect.self,
      of: {
        $0.frame(in: .named(coordinateSpaceName))
      },
      action: { value in
        self.stretchingValue = max(0, value.minY)
      })

  }
}

private let coordinateSpaceName = "app.muukii.stickyHeader.scrollView"

extension View {

  public func enableStickyHeader() -> some View {
    coordinateSpace(name: coordinateSpaceName)
  }

}

#Preview("dynamic") {
  ScrollView {
    
    StickyHeader(sizing: .content) {
          
      ZStack {
        
        Color.red          
          .padding(.top, -100)          
                  
        VStack {
          Text("StickyHeader")
          Text("StickyHeader")
          Text("StickyHeader")
        }
        .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.yellow)               
      }
      
    }
    
    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
  .enableStickyHeader()
  .padding(.vertical, 100)
}

#Preview("dynamic full") {
  ScrollView {
    
    StickyHeader(sizing: .content) {
      
      ZStack {
        
        Color.red
        
        VStack {
          Text("StickyHeader")
          Text("StickyHeader")
          Text("StickyHeader")
        }
        .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.yellow)
        .background(
          Color.green
            .padding(.top, -100)
          
        )
      }
      
    }
    
    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
  .enableStickyHeader()
}

#Preview("fixed") {
  ScrollView {
    
    StickyHeader(sizing: .fixed(300)) {
      
      Rectangle()
        .stroke(lineWidth: 10)
        .overlay(
          VStack {
            Text("StickyHeader")
            Text("StickyHeader")
            Text("StickyHeader")
          }
        )
    }
    
    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
  .enableStickyHeader()
  .padding(.vertical, 100)
}

#Preview("fixed full") {
  ScrollView {
    
    StickyHeader(sizing: .fixed(300)) {
            
      ZStack {
        
        Color.red
        
        VStack {
          Text("StickyHeader")
          Text("StickyHeader")
          Text("StickyHeader")
        }
        .border(Color.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.yellow)
        .background(
          Color.green
            .padding(.top, -100)

        )
      }
    }
    
    ForEach(0..<100, id: \.self) { _ in
      Text("Hello World!")
        .frame(maxWidth: .infinity)
    }
  }
  .enableStickyHeader()

}
