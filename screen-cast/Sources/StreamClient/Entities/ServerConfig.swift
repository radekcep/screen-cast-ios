//
//  ServerConfig.swift
//  
//
//  Created by Radek Čep on 23.03.2022.
//

import Foundation

public struct ServerConfig {
    public let address: String
    public let port: Int
    public let videoWidth: Int
    public let videoHeight: Int
}

public extension ServerConfig {
    static let `default`: Self = .init(
        address: "192.168.1.162",
        port: 8090,
        videoWidth: 1125,
        videoHeight: 2436
    )
}
