//
//  StreamClient.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import AVFoundation
import ComposableArchitecture
import Foundation
import ReplayKit

public struct StreamClient {
    public enum Action: Equatable {
        case serverRunning(URL)
    }

    public enum Error: Swift.Error {
        case unableToStartServer(Swift.Error)
        case unableToCloseRunningServer(Swift.Error)
        case wifiAddressUnavailable
        case invalidIPAddress
    }

    public var startServer: (ServerConfig) -> Effect<Action, Error>
    public var writeBuffer: (CMSampleBuffer, RPSampleBufferType) -> Void
}
