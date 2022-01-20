//
//  HLSClient.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import AVFoundation
import Foundation

public struct HLSClient {
    public var startServer: () -> Void
    public var writeBuffer: (CMSampleBuffer) -> Void
}
