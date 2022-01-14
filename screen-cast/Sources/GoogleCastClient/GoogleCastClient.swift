//
//  GoogleCastClient.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import ComposableArchitecture
import Foundation

public struct GoogleCastClient {
    public var receivers: () -> Effect<[GoogleCastReceiver], GoogleCastError>
}
