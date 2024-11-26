//
//  TrackingScrollView.swift
//  swift-dynamic-list
//
//  Created by Muukii on 2024/11/26.
//

import SwiftUI

public struct TrackingScrollView<Content: View>: View {
  
  public var body: some View {
    ScrollView { 
      LazyVStack {
        ForEach(0..<100) { index in
          Text("Item \(index)")
        }
      }
    }       
  }
}

