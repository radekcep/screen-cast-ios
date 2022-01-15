//
//  AppReducer.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import ComposableArchitecture
import Foundation

public let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    default:
        return .none
    }
}
