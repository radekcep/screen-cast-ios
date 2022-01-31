//
//  ExtensionAction.swift
//  
//
//  Created by Radek Čep on 31.01.2022.
//

import Foundation
import ReplayKit

public enum ExtensionAction: Equatable {
    case broadcastStarted
    case processSampleBuffer(CMSampleBuffer, RPSampleBufferType)
}
