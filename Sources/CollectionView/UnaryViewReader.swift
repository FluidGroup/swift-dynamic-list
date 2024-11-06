import SwiftUI

/// https://movingparts.io/variadic-views-in-swiftui
struct UnaryViewReader<ReadingContent: View, Content: View>: View {

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
    _VariadicView.Tree(_UnaryView(content: content)) {
      readingContent
    }
  }

}

struct MultiViewReader<ReadingContent: View, Content: View>: View {
  
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
    _VariadicView.Tree(_MultiView(content: content)) {
      readingContent
    }
  }
  
}

private struct _UnaryView<Content: View>: _VariadicView_UnaryViewRoot {

  let content: (_VariadicView_Children) -> Content

  init(@ViewBuilder content: @escaping (_VariadicView_Children) -> Content) {
    self.content = content
  }

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    content(children)
  }
}

private struct _MultiView<Content: View>: _VariadicView_MultiViewRoot {
  
  let content: (_VariadicView_Children) -> Content
  
  init(@ViewBuilder content: @escaping (_VariadicView_Children) -> Content) {
    self.content = content
  }
  
  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    content(children)
  }
}

#Preview {

  VStack {

    UnaryViewReader(
      readingContent: Group {
        
        ForEach(0..<10) { index in
          Text(index.description)
        }
        
        Text("1")
        Text("1")
        Text("1")
      },
      content: { children in
        ForEach(children) { child in 
          VStack {
            HStack {
              Text("🐵")
              child            
            }
            Text("ID: \(child.id)")
          }
        }        
      })

  }

}
