//
//  FloatingButton.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 21.12.2020.
//

import SwiftUI

struct FloatingButton: View {
    var iconOn = "questionmark"
    var iconOff = "questionmark"
    var size: CGFloat
    var toggled: Bool
    
    var body: some View {
        ZStack {
            Image(systemName: toggled ? iconOn : iconOff)
                .imageScale(.large)
                .foregroundColor(toggled ? .green : .white)
        }
    }
}

func floatingButton(iconOn: String = "questionmark", iconOff: String = "questionmark", size: CGFloat, toggled: Bool, onPress: @escaping () -> Void) -> AnyView {
    AnyView(
        FloatingButton(iconOn: iconOn, iconOff: iconOff, size: size, toggled: toggled).onTapGesture(perform: onPress)
    )
}
