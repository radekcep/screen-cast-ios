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
import HLSClient
import ReplayKit

public let extensionReducer = Reducer<ExtensionState, ExtensionAction, ExtensionEnvironment> { _, action, environment in
    switch action {
    case .broadcastStarted:
        let serverConfig = ServerConfig.default
        environment.hlsClient.startServer(serverConfig)

        return environment.googleCastClient.startDiscovery()
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case let .processSampleBuffer(sampleBuffer, sampleBufferType):
        environment.hlsClient.writeBuffer(sampleBuffer, sampleBufferType)
        return .none

    case .googleCastClient(.discovered):
        // TODO: SettingsClient doesn't work in an extension
        //        guard let selectedReceiverID = environment.settingsClient.savedUserSettings().selectedReceiverID else {
        //            // TODO: Show an user-facing error
        //            return .none
        //        }

        // TODO: GoogleCastReceiver name should not be empty
        let castReceiver = GoogleCastReceiver(id: "com.google.cast.CastDevice:4b6efcf52cf2a9f1e64eb1f7943e4b6c", name: "")
        // TODO: Deal with errors here
        return environment.googleCastClient.startSession(castReceiver)
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case .googleCastClient(.sessionStarted):
        let serverConfig = ServerConfig.default

        // TODO: Deal with errors here
        let contentURL = URL(string: "http://\(serverConfig.address):\(serverConfig.port)/playlist.m3u8")!
        let mediaConfig = MediaConfig(url: contentURL)

        return environment.googleCastClient.loadMedia(mediaConfig)
            .catch { _ in Empty() }
            .setFailureType(to: Never.self)
            .compactMap(ExtensionAction.googleCastClient)
            .eraseToEffect()

    case .googleCastClient:
        return .none
    }
}
