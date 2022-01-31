//
//  ExtensionReducer.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Combine
import ComposableArchitecture
import Foundation
import ReplayKit

public let extensionReducer = Reducer<ExtensionState, ExtensionAction, ExtensionEnvironment> { _, action, environment in
    switch action {
    case .broadcastStarted:
        environment.hlsClient.startServer()
        return .none

    case let .processSampleBuffer(sampleBuffer, sampleBufferType):
        if sampleBufferType == RPSampleBufferType.video {
            environment.hlsClient.writeBuffer(sampleBuffer)
        }
        return .none
    }
}
