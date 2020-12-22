//
//  ControlCommandHandler.swift
//  Sony Remote WatchKit Extension
//
//  Created by Marius Ghita on 06.12.2020.
//

import Foundation

enum ControlCommand: String {
    case Left,
         Right,
         Up,
         Down,
         Tap,
         DoubleTap,
         TrippleTap,
         CrownUp,
         CrownDown
}

protocol ControlCommandHandlerDelegate {
    func onVolumeUp()
    func onVolumeDown()
    func onConfirmTwice()
    func onPower()
}

protocol TVControlCommandHandlerDelegate: ControlCommandHandlerDelegate {
    func onNextChannel()
    func onPrevChannel()
}

protocol AppControlCommandHandlerDelegate: ControlCommandHandlerDelegate {
    func onMoveUp()
    func onMoveDown()
    func onMoveLeft()
    func onMoveRight()
    func onConfirm()
}

class ControlCommandHandler {
    var delegate: ControlCommandHandlerDelegate?
    
    init(delegate: ControlCommandHandlerDelegate) {
        self.delegate = delegate
    }
    
    func handleCommand(_ command: ControlCommand) {
        switch command {
        case .CrownDown:
            delegate?.onVolumeDown()
            break
        case .CrownUp:
            delegate?.onVolumeUp()
            break
        case .DoubleTap:
            delegate?.onConfirmTwice()
            break
        case .TrippleTap:
            delegate?.onPower()
            break
        default:
            break
        }
    }
}

class TVControlCommandHandler: ControlCommandHandler {
    override func handleCommand(_ command: ControlCommand) {
        guard let appDelegate = delegate as? TVControlCommandHandlerDelegate else {
            (self as ControlCommandHandler).handleCommand(command)
            return
        }

        switch command {
        case .Left, .Down:
            appDelegate.onPrevChannel()
            break
        case .Right, .Up:
            appDelegate.onNextChannel()
            break
        default:
            super.handleCommand(command)
            break
        }
    }
}

class AppControlCommandHandler: ControlCommandHandler {
    override func handleCommand(_ command: ControlCommand) {
        guard let appDelegate = delegate as? AppControlCommandHandlerDelegate else {
            (self as ControlCommandHandler).handleCommand(command)
            return
        }

        switch command {
        case .Left:
            appDelegate.onMoveLeft()
            break
        case .Right:
            appDelegate.onMoveRight()
            break
        case .Down:
            appDelegate.onMoveDown()
            break
        case .Up:
            appDelegate.onMoveUp()
            break
        case .Tap:
            appDelegate.onConfirm()
            break
        default:
            super.handleCommand(command)
            break
        }
    }
}
