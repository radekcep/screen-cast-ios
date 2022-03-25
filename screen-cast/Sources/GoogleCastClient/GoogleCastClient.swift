//
//  GoogleCastClient.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import ComposableArchitecture
import Foundation

public struct GoogleCastClient {
    public enum Action: Equatable {
        case discovered(receivers: [GoogleCastReceiver])
        case sessionStarted(GoogleCastReceiver.ID)
        case sessionEnded
        case requestCompleted
    }

    public enum Error: Swift.Error {
        case deviceUnavailable
        case sessionInterrupted
        case unableToStartSession
        case unableToLoadMedia
        case mediaRequestAborted
    }

    public var startDiscovery: () -> Effect<Action, Never>
    public var startSession: (GoogleCastReceiver) -> Effect<Action, Error>
    public var loadMedia: (MediaConfig) -> Effect<Action, Error>
}

extension GoogleCastClient.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            return "Device unavailable"
        case .sessionInterrupted:
            return "Session interrupted"
        case .unableToStartSession:
            return "Unable to start the session"
        case .unableToLoadMedia:
            return "Unable to load media request"
        case .mediaRequestAborted:
            return "Media request was aborted"
        }
    }
}
