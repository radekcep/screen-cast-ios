//
//  ExtensionEnvironment.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Foundation
import ComposableArchitecture
import GoogleCastClient
import HLSClient
import SettingsClient

public struct ExtensionEnvironment {
    public var finishBroadcastWithError: (Error) -> Void
    public var googleCastClient: GoogleCastClient
    public var settingsClient: SettingsClient
    public var hlsClient: HLSClient

    public init(
        finishBroadcastWithError: @escaping (Error) -> Void,
        googleCastClient: GoogleCastClient,
        settingsClient: SettingsClient,
        hlsClient: HLSClient
    ) {
        self.finishBroadcastWithError = finishBroadcastWithError
        self.googleCastClient = googleCastClient
        self.settingsClient = settingsClient
        self.hlsClient = hlsClient
    }
}
