//
//  GoogleCastClient.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import ComposableArchitecture
import Foundation

public struct GoogleCastClient {
    public enum Action: Equatable {
        case discovered(receivers: [GoogleCastReceiver])
    }

    public enum Error: Swift.Error {
    }

    public var startDiscovery: () -> Effect<Action, Never>
}
