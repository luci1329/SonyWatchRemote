//
//  GestureControlView.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 12.12.2020.
//

import SwiftUI

struct GestureControlView: View {
    var commandHanlerDelegate: ControlCommandHandlerDelegate!
    
    @State var scrollAmount: CGFloat = 0.0
    @State var isDetectingLongPress = false
    @State var isFocused = false
    @State private var firstToggle = false
    @Binding var commandHandler: ControlCommandHandler?
    @State var startPos : CGPoint = .zero
    @State var isSwipping = true
    
    var body: some View {

        let scroll = Binding<CGFloat>(
            get: {
                self.scrollAmount
            },
            set: {
                let newValue = Int($0)
                let oldValue = Int(self.scrollAmount)
                
                if newValue > oldValue {
                    commandHandler?.handleCommand(ControlCommand.CrownUp)
                } else if newValue < oldValue {
                    commandHandler?.handleCommand(ControlCommand.CrownDown)
                }

                self.scrollAmount = $0
            }
        )
                
        VStack(alignment: .leading, spacing: nil, content: {
            Text("Control Pad").font(.subheadline).foregroundColor(isFocused ? .green : .white)
        })  .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.black)
            .cornerRadius(10)
            .focusable(true, onFocusChange: { (focused) in
                isFocused = focused
            })
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(isFocused ? Color.green : Color.white, lineWidth: 1)
            )
            .onTapGesture(count: 2, perform: {
                commandHandler?.handleCommand(ControlCommand.DoubleTap)
            })
            .onTapGesture {
                commandHandler?.handleCommand(ControlCommand.Tap)
            }
            .onLongPressGesture(minimumDuration: 2, maximumDistance: 50, pressing: nil, perform: {
                commandHandler?.handleCommand(ControlCommand.TrippleTap)
            })
            .gesture(swipeGesture())
            .digitalCrownRotation(scroll, from: 0, through: 100, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
    }
    
    func swipeGesture() -> some Gesture {
        return DragGesture()
            .onChanged({ (gesture) in
                if self.isSwipping {
                    self.startPos = gesture.location
                    self.isSwipping.toggle()
                }
            }).onEnded({ (gesture) in
                let xDist =  abs(gesture.location.x - self.startPos.x)
                let yDist =  abs(gesture.location.y - self.startPos.y)
                if self.startPos.y <  gesture.location.y && yDist > xDist {
                    commandHandler?.handleCommand(ControlCommand.Down)
                }
                else if self.startPos.y >  gesture.location.y && yDist > xDist {
                    commandHandler?.handleCommand(ControlCommand.Up)
                }
                else if self.startPos.x > gesture.location.x && yDist < xDist {
                    commandHandler?.handleCommand(ControlCommand.Left)
                }
                else if self.startPos.x < gesture.location.x && yDist < xDist {
                    commandHandler?.handleCommand(ControlCommand.Right)
                }
                
                self.isSwipping.toggle()
            })
    }
}
