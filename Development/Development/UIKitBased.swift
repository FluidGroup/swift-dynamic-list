
import UIKit
import SwiftUI
import swift_dynamic_list

struct BookUIKitBased: View, PreviewProvider {
  var body: some View {
    Content()
  }

  static var previews: some View {
    Self()
  }

  private struct Content: View {

    var body: some View {
      Text("Book")
    }
  }
}

