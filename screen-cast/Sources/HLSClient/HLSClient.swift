//
//  HLSClient.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import AVFoundation
import Foundation
import ReplayKit

public struct HLSClient {
    public var startServer: (ServerConfig) -> Void
    public var writeBuffer: (CMSampleBuffer, RPSampleBufferType) -> Void
}
