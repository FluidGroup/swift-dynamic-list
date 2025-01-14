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
        ForEach(items, id: \.self) { index in            
          Text("Item \(index)")
            .font(.title)
        }
      }
      if isLoading {
        Text(isLoading ? "Loading..." : "End")
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


