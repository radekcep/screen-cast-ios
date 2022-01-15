//
//  AppAction.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCastClient

public enum AppAction {
    case googleCastClient(GoogleCastClient.Action)
}
