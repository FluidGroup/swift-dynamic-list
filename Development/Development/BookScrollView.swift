//
//  BookScrollView.swift
//  Development
//
//  Created by Muukii on 2024/11/26.
//

import SwiftUI
import ScrollTracking

struct OnAdditionalLoading_Previews: View, PreviewProvider {

  @State var items: [Int] = (0..<100).map { $0 }
  @State var isLoading: Bool = false

  var body: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
        Section {
          ForEach(items, id: \.self) { index in
            Cell(
              name: "Item \(index)",
              actionHandler: {
                print("Update \(index)")
            })
          }
        } footer: {
          if isLoading {
            Text(isLoading ? "Loading..." : "End")
          }
        }
      }
    }
    .onAdditionalLoading(isLoading: $isLoading) {
      print("👨🏻 load")
      try? await Task.sleep(for: .seconds(1))
      items.append(contentsOf: (items.count..<(items.count + 100)).map { $0 })
      print("appended")
    }
  }

  static var previews: some View {
    Self()
  }
}

private struct Cell: View {

  let name: String
  let actionHandler: () -> Void

  var body: some View {
    let _ = print("Render \(name)")
    Text(name)
      .font(.title)
  }
}
