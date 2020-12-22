//
//  ContentView.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 05.12.2020.
//

import SwiftUI

struct RemoteButton: Hashable {
    var displayName: String!
    var remoteValue: String?
    private (set) var onPress: (() -> Void)!
    private (set) var tag: Int!
    
    init(displayName: String, remoteValue: String, onPress: @escaping () -> Void) {
        self.displayName = displayName
        self.remoteValue = remoteValue
        self.onPress = onPress
        self.tag = -1
    }
    
    init(displayName: String, tag: Int, onPress: @escaping () -> Void) {
        self.displayName = displayName
        self.remoteValue = ""
        self.onPress = onPress
        self.tag = tag
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName + (remoteValue ?? ""))
    }
    
    static func == (lhs: RemoteButton, rhs: RemoteButton) -> Bool {
        lhs.displayName == rhs.displayName
    }
}

enum RemoteCommand: String, CaseIterable {
    case VolumeUp = "VolumeUp"
    case VolumeDown = "VolumeDown"
    case Power = "TvPower"
    case TV = "Tv"
    case Youtube = "YouTubex"
    case Netflix = "Netflix"
    case Home = "Home"
    case Back = "Return"
    case Guide = "GGuide"
    case Left = "Left"
    case Up = "Up"
    case Down = "Down"
    case Right = "Right"
    case Confirm = "Confirm"
    case ChannelUp = "ChannelUp"
    case ChannelDown = "ChannelDown"
    
    func hapticType() -> WKHapticType {
        if self == .VolumeUp || self == .VolumeDown {
            return .click
        }
        
        return .success
    }
}

extension RemoteCommand {
    static func actionMenuArray() -> [RemoteCommand] {
        return [.Power, .TV, .Guide, .Youtube, .Netflix]
    }
}

struct ContentView: View {
    @State var isLoadingRemoteCommands = false
    @State var displayActionMenu = false
    @State var commandHandler: ControlCommandHandler?
    @State var showErrorAlert = false
    @State var segmentedControlHighlightedTag = 0
    @State var hasCommands = false
    @State var requestError: RequestError? {
        didSet {
            showErrorAlert = requestError != nil
        }
    }
    
    private var requestHandler = RequestHandler()
    
    init() {
        fetchCommands()
    }
        
    var body: some View {
        ZStack(alignment: .center) {
            mainContentView()
            .blur(radius: isLoadingRemoteCommands ? 1 : 0)
            .progressViewStyle(CircularProgressViewStyle())
            .edgesIgnoringSafeArea(.bottom)
            .sheet(isPresented: $displayActionMenu, content: {actionMenuView()})
            .alert(isPresented: $showErrorAlert, content: {
                Alert(title: Text("Error"), message: Text(requestError!.errorMessage), dismissButton: .default(Text("Close"), action: {requestError = nil}))
            })
            
            if isLoadingRemoteCommands {
                loadingProgressView()
            }
        }
    }
    
    func fetchCommands() {
        isLoadingRemoteCommands = true
        requestHandler.getRemoteCommands { (cmds, error) in
            isLoadingRemoteCommands = false
            
            guard let error = error else {
                hasCommands = true
                playHaptic(type: .success)
                enableAppControl()
                return
            }
            
            setError(error: error)
        }
    }
    
    func loadingProgressView() -> some View {
        ProgressView("Loading Remote Commands...")
            .background(Color.black)
            .opacity(0.8)
            .multilineTextAlignment(.center)
    }
    
    func errorAlertView(error: RequestError) -> some View {
        VStack(alignment: .center, spacing: 5, content: {
            Text(error.errorMessage).multilineTextAlignment(.center)
            Spacer(minLength: 5)
            Button("Close") {
                requestError = nil
            }
        })
    }
    
    func mainContentView() -> some View {
        VStack(spacing: 5, content: {
            Text("Sony Remote").font(.headline)
            GestureControlView(commandHandler: $commandHandler)
                .overlay(gestureControlViewOverlay())
            SegmentedControl(values: segmentedControlViews(), highlightedTag: $segmentedControlHighlightedTag)
                .padding(.vertical, 5)
        })
    }
    
    func gestureControlViewOverlay() -> some View {
        GeometryReader { geometry in
            FloatingButton(icon: "", size: 15, toggled: $hasCommands)
                .position(x: geometry.size.width - 15, y: 15)
                .onTapGesture {
                    
                }
        }
    }
    
    func segmentedControlViews() -> [RemoteButton] {
        [
            RemoteButton(displayName: "Home", tag: 0, onPress: {
                enableAppControl()
                sendRemoteCommand(command: .Home)
                segmentedControlHighlightedTag = 0
            }),
            RemoteButton(displayName: "TV", tag: 1, onPress: {
                enableTvControl()
                sendRemoteCommand(command: .TV)
                segmentedControlHighlightedTag = 1
            }),
            RemoteButton(displayName: "Back", tag: 2, onPress: {
                sendRemoteCommand(command: .Back)
            })
        ]
    }
    
    func actionMenuView() -> AnyView {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        guard let requestError = requestError else {
            return AnyView(
                ScrollView(.vertical, showsIndicators: true, content: {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 5, pinnedViews: [], content: {
                        ForEach(RemoteCommand.actionMenuArray(), id: \.self) { command in
                            Button(String(describing: command)) {
                                actionMenuButtonPressed(command: command)
                            }
                        }
                    })
                })
            )
        }
        
        return AnyView(
            ScrollView(.vertical, showsIndicators: true, content:{
                errorAlertView(error: requestError)
            })
        )
    }
    
    func playHaptic(command: RemoteCommand) {
        WKInterfaceDevice.current().play(command.hapticType())
    }
    
    func playHaptic(type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    func setError(error: RequestError) {
        requestError = error
        playHaptic(type: WKHapticType.failure)
    }
    
    func actionMenuButtonPressed(command: RemoteCommand) {
        sendRemoteCommand(command: command)
    }
    
    private func enableAppControl() {
        commandHandler = AppControlCommandHandler(delegate: self)
    }
    
    private func enableTvControl() {
        commandHandler = TVControlCommandHandler(delegate: self)
    }
    
    private func sendRemoteCommand(command: RemoteCommand) {
        print(command)
        requestHandler.sendRemoteCommand(command: command.rawValue) { (error) in
            if let error = error {
                setError(error: error)
            } else {
                requestError = nil
                playHaptic(command: command)
            }
        }
    }
}

extension ContentView: ControlCommandHandlerDelegate {
    func onVolumeUp() {
        sendRemoteCommand(command: .VolumeUp)
    }
    
    func onVolumeDown() {
        sendRemoteCommand(command: .VolumeDown)
    }
    
    func onPower() {
        sendRemoteCommand(command: .Power)
    }
    
    func onConfirmTwice() {
        displayActionMenu = true
        WKInterfaceDevice.current().play(.success)
    }
}

extension ContentView: TVControlCommandHandlerDelegate {
    func onNextChannel() {
        sendRemoteCommand(command: .ChannelUp)
    }
    
    func onPrevChannel() {
        sendRemoteCommand(command: .ChannelDown)
    }
}

extension ContentView: AppControlCommandHandlerDelegate {
    func onMoveUp() {
        sendRemoteCommand(command: .Up)
    }
    
    func onMoveDown() {
        sendRemoteCommand(command: .Down)
    }
    
    func onMoveLeft() {
        sendRemoteCommand(command: .Left)
    }
    
    func onMoveRight() {
        sendRemoteCommand(command: .Right)
    }
    
    func onConfirm() {
        sendRemoteCommand(command: .Confirm)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("Apple Watch Series 6 - 44mm")
            
    }
}
