//
//  ExtensionAction.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Foundation
import GoogleCastClient
import ReplayKit
import StreamClient

public enum ExtensionAction: Equatable {
    case broadcastStarted
    case processSampleBuffer(CMSampleBuffer, RPSampleBufferType)
    case googleCastClient(GoogleCastClient.Action)
    case streamClient(StreamClient.Action)
}
