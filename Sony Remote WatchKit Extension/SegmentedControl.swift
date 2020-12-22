//
//  SegmentedControl.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 13.12.2020.
//

import SwiftUI

struct SegmentedControl: View {
    var values: [RemoteButton] = []
    @State var isFocused = false
    @Binding var highlightedTag: Int
    
//    init(highlightedTag: Binding<Int>, elements: [RemoteButton]) {
//        values = elements
//        self._highlightedTag = highlightedTag
//    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 15, content: {
            ForEach(values.indices) { i in
                Text(values[i].displayName).onTapGesture(perform: values[i].onPress)
                    .foregroundColor(highlightedTag == values[i].tag ? Color.green : Color.white)
                if (i < values.count - 1) {
                    Divider().frame(width: 1, height: 30, alignment: .center)
                }
            }
        })
    }
}
