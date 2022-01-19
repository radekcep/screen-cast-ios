//
//  AppState.swift
//  
//
//  Created by Radek Čep on 13.01.2022.
//

import Foundation
import ComposableArchitecture
import GoogleCastClient
import SettingsClient

public struct AppState: Equatable {
    public var error: AlertState<AppAction>?
    public var receivers: [GoogleCastReceiver]
    public var userSettings: UserSettings?

    public init(
        error: AlertState<AppAction>? = nil,
        receivers: [GoogleCastReceiver] = [],
        userSettings: UserSettings? = nil
    ) {
        self.error = error
        self.receivers = receivers
        self.userSettings = userSettings
    }
}
