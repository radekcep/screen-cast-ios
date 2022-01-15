//
//  GoogleCastReceiver.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import Foundation
import GoogleCast

public struct GoogleCastReceiver: Identifiable, Equatable {
    public let id: String
    public let name: String
}

extension GoogleCastReceiver {
    init(gckDevice: GCKDevice) {
        id = gckDevice.uniqueID
        name = gckDevice.friendlyName
            ?? gckDevice.modelName
            ?? gckDevice.deviceID
    }
}
