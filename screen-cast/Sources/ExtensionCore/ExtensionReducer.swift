//
//  ExtensionReducer.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Combine
import ComposableArchitecture
import Foundation
import GoogleCastClient
import StreamClient
import ReplayKit

// TODO: Deal with errors here
public let extensionReducer = Reducer<ExtensionState, ExtensionAction, ExtensionEnvironment> { state, action, environment in
    switch action {
    case .broadcastStarted:
        let serverConfig = ServerConfig.default

        return environment.streamClient.startServer(serverConfig)
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.streamClient)
            .receive(on: environment.mainQueue)
            .eraseToEffect()

    case let .streamClient(.serverRunning(url)):
        state.serverURL = url

        return environment.googleCastClient.startDiscovery()
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case .googleCastClient(.discovered):
        // TODO: SettingsClient doesn't work in an extension
        // TODO: GoogleCastReceiver name should not be empty
        let castReceiver = GoogleCastReceiver(
            id: "com.google.cast.CastDevice:4b6efcf52cf2a9f1e64eb1f7943e4b6c",
            name: ""
        )

        return environment.googleCastClient.startSession(castReceiver)
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case .googleCastClient(.sessionStarted):
        guard let url = state.serverURL else {
            return .none
        }

        let mediaConfig = MediaConfig(url: url)

        return environment.googleCastClient.loadMedia(mediaConfig)
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case let .processSampleBuffer(sampleBuffer, sampleBufferType):
        environment.streamClient.writeBuffer(sampleBuffer, sampleBufferType)
        return .none

    case .googleCastClient, .streamClient:
        return .none
    }
}
