//
//  ContentView.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 05.12.2020.
//

import SwiftUI

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
        return [.Power, .TV, .Guide, .Youtube, .Netflix, .Home]
    }
}

enum ActiveSheet: Identifiable {
    case Error, CredentialsInput, TvOptions
    
    var id: Int {
        hashValue
    }
}

struct ContentView: View {
    @State var commandHandler: ControlCommandHandler?
    @State var segmentedControlHighlightedTag = 1
    @State var hasCommands = false
    @State var activeSheet: ActiveSheet?
    @State var viewDidLoad = false
    @State var isLoadingCommands = false
    @State var isSendingCommand = false

    var isLoading: Bool {
        return isLoadingCommands || isSendingCommand
    }
    
    @State var requestError: RequestError? {
        didSet {
            activeSheet = requestError != nil ? .Error : nil
        }
    }
    
    private var requestHandler = RequestHandler()
    
    var body: some View {
        let tvIpInputProxy = Binding<String>(
            get: { self.requestHandler.getTvIpInput() },
            set: { self.requestHandler.setTvIpInput(ip: $0) }
        )
        
        let tvPskInputProxy = Binding<String>(
            get: { self.requestHandler.getTvPskInput() },
            set: { self.requestHandler.setTvPskInput(psk: $0) }
        )

        ZStack(alignment: .center) {
            mainContentView()
            .progressViewStyle(CircularProgressViewStyle())
            .sheet(item: $activeSheet, content: { item in
                switch item {
                case .Error:
                    errorAlertView(error: requestError!)
                case .CredentialsInput:
                    VStack {
                        TextField("TV IP", text: tvIpInputProxy)
                        SecureField("TV PSK", text: tvPskInputProxy)
                        Button("Connect") {
                            fetchCommands(fullReload: true)
                            activeSheet = nil
                        }
                    }
                case .TvOptions:
                    actionMenuView()
                }
            })
            .onAppear {
                if !viewDidLoad {
                    fetchCommands()
                }
                
                viewDidLoad = true
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func fetchCommands(fullReload: Bool = false) {
        isLoadingCommands = true
        hasCommands = false
        requestHandler.getRemoteCommands(fullReload: fullReload) { (cmds, error) in
            isLoadingCommands = false

            guard let error = error else {
                hasCommands = true
                playHaptic(type: .success)
                enableAppControl()
                return
            }
            
            if (error.code != .Cancelled) {
                setError(error: error)
            }
        }
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
            HStack {
                if isLoading {
                    ProgressView().scaleEffect(0.5, anchor: .center).frame(width: 20, height: 10, alignment: .center)
                }
                Spacer()
                Text("Sony Remote").font(.system(size: 15)).padding(.leading, isLoading ? 0 : 20)

                Spacer()
                FloatingButton(iconOn: "tv.circle.fill", iconOff: "tv.circle", size: 20, toggled: hasCommands)
                    .onTapGesture {activeSheet = .CredentialsInput}
            }
            GestureControlView(commandHandler: $commandHandler)
            SegmentedControl(values: segmentedControlViews())
                .padding(.vertical, 5)
        })
    }
    
    func segmentedControlViews() -> [AnyView] {
        [
            floatingButton(iconOff: "arrow.uturn.backward", size: 20, toggled: false, onPress: {
                sendRemoteCommand(command: .Back)
            }),
            floatingButton(iconOn: "square.grid.3x3.fill", iconOff: "square.grid.3x3", size: 20, toggled: segmentedControlHighlightedTag == 1, onPress: {
                enableAppControl()
                segmentedControlHighlightedTag = 1
            }),
            floatingButton(iconOn: "tv.fill", iconOff: "tv", size: 20, toggled: segmentedControlHighlightedTag == 2, onPress: {
                enableTvControl()
                segmentedControlHighlightedTag = 2
            }),
        ]
    }
    
    func actionMenuView() -> AnyView {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
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
        guard !isLoadingCommands else { return }
        
        print(command)
        isSendingCommand = true

        requestHandler.sendRemoteCommand(command: command.rawValue) { (error) in
            isSendingCommand = false
            if let error = error, error.code != .Cancelled {
                setError(error: error)
            } else if error == nil {
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
        activeSheet = .TvOptions
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
