import SwiftUI

public struct StickyHeaderContext {

  public enum Phase {
    case idle
    case stretching
  }

  public let topMargin: CGFloat
  public let phase: Phase

  init(
    topMargin: CGFloat,
    phase: Phase
  ) {
    self.topMargin = topMargin
    self.phase = phase
  }
}

///
/// A view that sticks to the top of the screen in a ScrollView.
/// When it's bouncing, it stretches the content.
/// To use this view, you need to call ``View.enableStickyHeader()`` modifier to the ScrollView.
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
  public let content: (StickyHeaderContext) -> Content

  @State var baseContentHeight: CGFloat?
  @State var stretchingValue: CGFloat = 0
  @State var topMargin: CGFloat = 0

  public init(
    sizing: Sizing,
    @ViewBuilder content: @escaping (StickyHeaderContext) -> Content
  ) {
    self.sizing = sizing
    self.content = content
  }

  public var body: some View {

    let offsetY: CGFloat = 0

    let context = StickyHeaderContext(
      topMargin: topMargin,
      phase: stretchingValue > 0 ? .stretching : .idle
    )

    Group {
      switch sizing {
      case .content:
        content(context)
          .onGeometryChange(for: CGSize.self, of: \.size) { size in
            if stretchingValue == 0 {
              baseContentHeight = size.height
            }
          }
          .frame(
            height: baseContentHeight.map {
              $0 + stretchingValue
            }
          )
          .offset(y: -stretchingValue)
          // container
          .frame(height: baseContentHeight, alignment: .top)

      case .fixed(let height):

        content(context)
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
        $0.frame(in: .global)
      },
      action: { value in
        let minY = value.minY
        if minY >= 0, topMargin != minY {
          topMargin = minY
        }
      }
    )
    .onGeometryChange(
      for: CGFloat.self,
      of: {
        $0.frame(in: .named(coordinateSpaceName)).minY
      },
      action: { value in
        self.stretchingValue = max(0, value)
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

    StickyHeader(sizing: .content) { context in

      ZStack {

        Color.red
          .padding(.top, -context.topMargin)

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

    StickyHeader(sizing: .content) { context in

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

    StickyHeader(sizing: .fixed(300)) { context in

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

    StickyHeader(sizing: .fixed(300)) { context in

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
            .padding(.top, -context.topMargin)

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
