//
//  ExtensionEnvironment.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Foundation
import ComposableArchitecture
import GoogleCastClient
import StreamClient
import SettingsClient

public struct ExtensionEnvironment {
    public var finishBroadcastWithError: (Error) -> Void
    public var googleCastClient: GoogleCastClient
    public var settingsClient: SettingsClient
    public var streamClient: StreamClient
    public var mainQueue: AnySchedulerOf<DispatchQueue> = .main

    public init(
        finishBroadcastWithError: @escaping (Error) -> Void,
        googleCastClient: GoogleCastClient,
        settingsClient: SettingsClient,
        streamClient: StreamClient
    ) {
        self.finishBroadcastWithError = finishBroadcastWithError
        self.googleCastClient = googleCastClient
        self.settingsClient = settingsClient
        self.streamClient = streamClient
    }
}
