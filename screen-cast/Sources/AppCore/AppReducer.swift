//
//  AppReducer.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Combine
import ComposableArchitecture
import Foundation
import GoogleCastClient
import TCAHelpers

public let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    struct GoogleCastReceiversID: Hashable { }

    switch action {
    case .onAppear:
        let startDiscovery = environment.googleCastClient.startDiscovery()
            .map(AppAction.googleCastClient)
            .cancellable(id: GoogleCastReceiversID())
            .eraseToEffect()
        let loadSettings = Just(AppAction.loadUserSettings)
            .eraseToEffect()
        return .merge(startDiscovery, loadSettings)

    case .onDisappear:
        return .cancel(id: GoogleCastReceiversID())

    case .loadUserSettings:
        state.userSettings = environment.settingsClient.savedUserSettings()
        return .none

    case let .save(userSettings):
        environment.settingsClient.save(userSettings)
        return .none

    case let .select(receiverID):
        state.userSettings?.selectedReceiverID = receiverID
        return .none

    case .deselectGoogleCastReceiver:
        state.userSettings?.selectedReceiverID = nil
        return .none

    case let .googleCastClient(.discovered(receivers: receivers)):
        state.receivers = receivers
        return .none

    case .googleCastClient:
        return .none

    case let .errorOccurred(description):
        state.error = .init(title: .init(description))
        return .none

    case .dismissError:
        state.error = nil
        return .none
    }
}
    .onChange(of: \.userSettings) { userSettings, _, _, environment in
        userSettings.map(environment.settingsClient.save)
        return .none
    }
    .debug()
