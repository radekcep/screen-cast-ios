//
//  AppAction.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCastClient
import SettingsClient

public enum AppAction: Equatable {
    case onAppear
    case onDisappear
    case loadUserSettings
    case save(UserSettings)
    case select(GoogleCastReceiver.ID)
    case deselectGoogleCastReceiver
    case googleCastClient(GoogleCastClient.Action)
    case errorOccurred(String)
    case dismissError
}
