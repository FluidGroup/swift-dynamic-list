import SwiftUI

public struct TopBar<Content: View>: View {
  
  private let content: Content
  private let height: CGFloat
  private let backgroundColor: Color
  
  public init(
    height: CGFloat = 44,
    backgroundColor: Color = Color(.systemBackground),
    @ViewBuilder content: () -> Content
  ) {
    self.height = height
    self.backgroundColor = backgroundColor
    self.content = content()
  }
  
  public var body: some View {
    content
      .frame(height: height)
      .frame(maxWidth: .infinity, alignment: .center)
    .background(
      backgroundColor
    )
  }
}

#Preview {
  VStack {
    TopBar {
      HStack {
        Text("Title")
          .font(.headline)
      }
      .padding(.horizontal)
    }
    Spacer()
  }
  .background(Color.purple)
}

