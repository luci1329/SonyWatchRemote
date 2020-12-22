//
//  FloatingButton.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 21.12.2020.
//

import SwiftUI

struct FloatingButton: View {
    var icon: String
    var size: CGFloat
    @Binding var toggled: Bool

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(toggled ? .green : .gray)
                .frame(width: size, height: size)
            Image(systemName: "add")
                .imageScale(.large)
                .foregroundColor(.white)
        }
//        .shadow(color: .gray, radius: 0.2, x: 1, y: 1)
    }
}
