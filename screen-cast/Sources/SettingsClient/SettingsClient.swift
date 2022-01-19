//
//  SettingsClient.swift
//  
//
//  Created by Radek Čep on 18.01.2022.
//

import ComposableArchitecture
import Foundation

public struct SettingsClient {
    public enum Action: Equatable {
    }

    public enum Error: Swift.Error {
    }

    public var savedUserSettings: () -> UserSettings
    public var save: (UserSettings) -> Void
}
