//
//  ContentSwitchView.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 13.12.2020.
//

import SwiftUI

struct ContentItemView: View {
    var body: some View {
        Text("")
    }
}

struct ContentSwitchView: View {
    @Binding var content: ContentItemView
    
    var body: some View {
        return content
    }
}
