//
//  AppEnvironment.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCastClient
import SettingsClient

public struct AppEnvironment {
    public var googleCastClient: GoogleCastClient
    public var settingsClient: SettingsClient

    public init(
        googleCastClient: GoogleCastClient,
        settingsClient: SettingsClient
    ) {
        self.googleCastClient = googleCastClient
        self.settingsClient = settingsClient
    }
}
