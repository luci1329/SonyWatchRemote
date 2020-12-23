//
//  SegmentedControl.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 13.12.2020.
//

import SwiftUI

struct SegmentedControl: View {
    var values: [AnyView] = []
    @State var isFocused = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 20, content: {
            ForEach(0..<values.count) { index in
                values[index]
                if (index < values.count - 1) {
                    Divider().frame(width: 1, height: 30, alignment: .center)
                }
            }
        })
    }
}
