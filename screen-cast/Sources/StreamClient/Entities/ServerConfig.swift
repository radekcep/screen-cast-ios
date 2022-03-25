//
//  ServerConfig.swift
//  
//
//  Created by Radek Čep on 23.03.2022.
//

import Foundation

public struct ServerConfig {
    public let videoWidth: Int
    public let videoHeight: Int
}

public extension ServerConfig {
    static let `default`: Self = .init(
        videoWidth: 1125,
        videoHeight: 2436
    )
}
