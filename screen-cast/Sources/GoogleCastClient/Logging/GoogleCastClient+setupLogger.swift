//
//  GoogleCastClient+setupLogger.swift
//  
//
//  Created by Radek Čep on 16.01.2022.
//

import Foundation
import GoogleCast

extension GoogleCastClient {
    static func setupLogger(with delegate: GCKLoggerDelegate?) {
        let logFilter = GCKLoggerFilter()
        let classesToLog = [
            "GCKDeviceScanner", "GCKDeviceProvider", "GCKDiscoveryManager",
            "GCKCastChannel", "GCKMediaControlChannel", "GCKUICastButton",
            "GCKUIMediaController", "NSMutableDictionary"
        ]

        logFilter.setLoggingLevel(.verbose, forClasses: classesToLog)
        GCKLogger.sharedInstance().filter = logFilter
        GCKLogger.sharedInstance().delegate = delegate
    }
}
