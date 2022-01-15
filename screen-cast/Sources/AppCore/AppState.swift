//
//  AppState.swift
//  
//
//  Created by Radek Čep on 13.01.2022.
//

import Foundation
import ComposableArchitecture
import GoogleCastClient

public struct AppState: Equatable {
    public var receivers: [GoogleCastReceiver]

    public init(
        receivers: [GoogleCastReceiver] = []
    ) {
        self.receivers = receivers
    }
}
