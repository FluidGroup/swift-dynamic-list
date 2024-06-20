import AsyncMultiplexImage
import AsyncMultiplexImage_Nuke
import DynamicList
import SwiftUI

#if DEBUG
struct BookVariadicView: View, PreviewProvider {
  var body: some View {

    List {

      NavigationLink {
        NativeContent()
          .navigationTitle("Native")
      } label: {
        Text("Native")
      }

    }

  }

  static var previews: some View {
    NavigationView {
      List {

        NavigationLink {
          NativeContent()
            .navigationTitle("Native")
        } label: {
          Text("Native")
        }

      }
    }
  }

  private struct NativeContent: View {

    @State var items: [Message] = MockData.randomMessages(count: 2000)

    var body: some View {
      VStack {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(
              items,
              content: {
                ComplexCell(message: $0)
              }
            )
          }
        }
      }
    }
  }

  static let url = URL(
    string:
      "https://images.unsplash.com/photo-1686726754283-3cf793dec0e6?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80"
  )!

  struct ComplexCell: View {

    let message: Message

    @State var count = 0

    var body: some View {

      HStack {
        Text(count.description)
        Text(message.text)

        AsyncMultiplexImage(
          multiplexImage: .init(identifier: "1", urls: [BookVariadicView.url]),
          downloader: AsyncMultiplexImageNukeDownloader(pipeline: .shared, debugDelay: 0),
          content: { phase in
            switch phase {
            case .empty:
              Color.gray
            case .success(let image):
              image
                .resizable()
                .scaledToFill()
            case .failure:
              Color.red
            case .progress:
              Color.blue
            }
          }
        )
        .frame(width: 50, height: 50)

      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.yellow)
      )
      .padding(8)
    }
  }

  struct Message: Identifiable {
    let id = UUID()
    var text: String
  }

  struct MockData {
    static let cannedText = [
      "Quisque maximus non est non condimentum.",
      "Praesent sit amet condimentum lacus, vel vehicula tellus. Cras non dolor vel nulla accumsan mollis.",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus risus libero, laoreet eget cursus vitae, malesuada quis magna. Sed tristique pharetra ultrices. Suspendisse vitae est quis leo auctor commodo eget vitae tortor. Sed convallis rutrum luctus. Fusce in nibh suscipit, venenatis est fringilla, sollicitudin mi.",
      "Aliquam euismod, tortor ut venenatis mattis, est neque rutrum massa, vitae laoreet nibh ex eu arcu. Curabitur ut augue in sem aliquam ultrices. Integer mollis mattis eros eget vulputate.",
      "Nam cursus semper lacinia. Nullam pretium massa auctor, vehicula augue ac, bibendum lorem.",
      "Hi",
    ]

    static func makeMessage() -> String {
      return cannedText.randomElement()!
    }

    static func randomMessages(count: Int) -> [Message] {
      var messages = [Message]()

      for _ in 0..<count {
        if let message = cannedText.randomElement() {
          messages.append(Message(text: message))
        }
      }
      return messages
    }
  }
}

#endif
