//
//  GoogleCastReceiver.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import Foundation
import GoogleCast
import Tagged

public struct GoogleCastReceiver: Identifiable, Equatable {
    // swiftlint:disable:next type_name
    public typealias ID = Tagged<GoogleCastReceiver, String>

    public let id: ID
    public let name: String

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }

    init(gckDevice: GCKDevice) {
        id = .init(
            rawValue: gckDevice.uniqueID
        )
        name = gckDevice.friendlyName
            ?? gckDevice.modelName
            ?? gckDevice.deviceID
    }
}
