//
//  SettingsClientStub.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import Foundation

#if DEBUG
extension SettingsClient {
    public static let stub: Self = .init(
        savedUserSettings: { .init() },
        save: { _ in }
    )
}
#endif
