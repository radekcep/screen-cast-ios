//
//  UserSettings.swift
//  
//
//  Created by Radek Čep on 18.01.2022.
//

import Foundation
import GoogleCastClient

public struct UserSettings: Equatable, Codable {
    public var selectedReceiverID: GoogleCastReceiver.ID?

    public init(selectedReceiverID: GoogleCastReceiver.ID? = nil) {
        self.selectedReceiverID = selectedReceiverID
    }

    enum CodingKeys: String, CodingKey {
        case selectedReceiverID
    }
}
