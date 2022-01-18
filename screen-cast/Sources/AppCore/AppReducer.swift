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

public let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    struct GoogleCastReceiversID: Hashable { }

    switch action {
    case .lifecycleAction(.onAppear):
        return environment.googleCastClient.startDiscovery()
            .map(AppAction.googleCastClient)
            .cancellable(id: GoogleCastReceiversID())

    case .lifecycleAction(.onDisappear):
        return .cancel(id: GoogleCastReceiversID())

    case let .startSession(receiver):
        return environment.googleCastClient.startSession(receiver)
            .map(AppAction.googleCastClient)
            .catch { Just(.errorOccurred($0.errorDescription ?? "Unknown error occurred")) }
            .eraseToEffect()

    case let .googleCastClient(.discovered(receivers: receivers)):
        state.receivers = receivers
        return .none

    case let .googleCastClient(.sessionStarted(activeSessionReceiverID)):
        state.selectedReceiverID = activeSessionReceiverID
        return .none

    case .googleCastClient(.sessionEnded):
        state.selectedReceiverID = nil
        return .none

    case let .errorOccurred(description):
        state.error = .init(title: .init(description))
        return .none

    case .dismissError:
        state.error = nil
        return .none
    }
}
    .debug()
