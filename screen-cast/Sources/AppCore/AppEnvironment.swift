//
//  AppEnvironment.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCastClient

public struct AppEnvironment {
    public var googleCastClient: GoogleCastClient

    public init(
        googleCastClient: GoogleCastClient
    ) {
        self.googleCastClient = googleCastClient
    }
}
