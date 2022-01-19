//
//  SettingsClient.swift
//  
//
//  Created by Radek Čep on 18.01.2022.
//

import Foundation
import GoogleCastClient
import Tagged

extension SettingsClient {
    public static var live: Self {
        let defaults = UserDefaults(suiteName: "radekcep.ScreenCast")!

        return .init(
            savedUserSettings: {
                .init(
                    selectedReceiverID: defaults.string(forKey: UserSettings.CodingKeys.selectedReceiverID.rawValue)
                        .flatMap(Tagged.init)
                )
            },
            save: { settings in
                defaults.set(
                    settings.selectedReceiverID?.rawValue,
                    forKey: UserSettings.CodingKeys.selectedReceiverID.rawValue
                )
            }
        )
    }
}
