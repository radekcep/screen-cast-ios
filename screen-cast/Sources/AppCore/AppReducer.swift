//
//  AppReducer.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import ComposableArchitecture
import Foundation
import GoogleCastClient

public let appReducer: Reducer<AppState, AppAction, AppEnvironment> = .combine(
    lifeCycleReducer.pullback(
        state: \.self,
        action: /.`self`,
        environment: { $0 }
    ),
    googleCastReducer.pullback(
        state: \.receivers,
        action: /AppAction.googleCastClient,
        environment: { _ in () }
    )
)

let lifeCycleReducer = Reducer<AppState, AppAction, AppEnvironment> { _, action, environment in
    struct GoogleCastReceiversID: Hashable { }

    switch action {
    case .lifecycleAction(.onAppear):
        return environment.googleCastClient.startDiscovery()
            .map(AppAction.googleCastClient)
            .cancellable(id: GoogleCastReceiversID())

    case .lifecycleAction(.onDisappear):
        return .cancel(id: GoogleCastReceiversID())

    default:
        return .none
    }
}

let googleCastReducer = Reducer<[GoogleCastReceiver], GoogleCastClient.Action, Void> { state, action, _ in
    switch action {
    case let .discovered(receivers: receivers):
        state = receivers

        return .none
    }
}
