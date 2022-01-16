//
//  AppAction.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCastClient

public enum LifecycleAction {
  case onAppear
  case onDisappear
}

public enum AppAction: Equatable {
    case googleCastClient(GoogleCastClient.Action)
    case startSession(GoogleCastReceiver)
    case lifecycleAction(LifecycleAction)
    case errorOccurred(String)
    case dismissError
}
