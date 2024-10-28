import SwiftUI

/// https://movingparts.io/variadic-views-in-swiftui
struct VariadicViewReader<ReadingContent: View, Content: View>: View {

  let readingContent: ReadingContent
  let content: (_VariadicView_Children) -> Content

  init(
    readingContent: ReadingContent,
    @ViewBuilder content: @escaping (_VariadicView_Children) -> Content
  ) {
    self.readingContent = readingContent
    self.content = content
  }

  // MARK: View

  var body: some View {
    _VariadicView.Tree(MultiViewForEach(content: content)) {
      readingContent
    }
  }

}

private struct MultiViewForEach<Content: View>: _VariadicView_MultiViewRoot {

  let content: (_VariadicView_Children) -> Content

  init(@ViewBuilder content: @escaping (_VariadicView_Children) -> Content) {
    self.content = content
  }

  // MARK: _VariadicView_MultiViewRoot

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    content(children)
  }
}

#Preview {

  VStack {

    VariadicViewReader(
      readingContent: Group {
        Text("1")
        Text("1")
        Text("1")
      },
      content: { children in
        ForEach(children) { child in 
          HStack {
            Text("🐵")
            child
          }
        }        
      })

  }

}
