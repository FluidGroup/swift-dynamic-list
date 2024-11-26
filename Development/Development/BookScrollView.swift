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
  
  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(items, id: \.self) { index in            
          Text("Item \(index)")
        }
      }
    }
    .onAdditionalLoading {
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


