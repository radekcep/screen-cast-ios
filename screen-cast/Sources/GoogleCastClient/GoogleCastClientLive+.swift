//
//  GoogleCastClientLive+.swift
//  
//
//  Created by Radek Čep on 15.01.2022.
//

import Foundation
import GoogleCast

extension GoogleCastClient {
    class DiscoveryManagerListener: NSObject, GCKDiscoveryManagerListener {
        private let _didUpdateDeviceList: () -> Void
        private let _didStartDiscovery: (_ deviceCategory: String) -> Void
        // swiftlint:disable:next identifier_name
        private let _didHaveDiscoveredDeviceWhenStartingDiscovery: () -> Void

        init(
            didUpdateDeviceList: @escaping () -> Void,
            didStartDiscovery: @escaping (_ deviceCategory: String) -> Void,
            // swiftlint:disable:next identifier_name
            didHaveDiscoveredDeviceWhenStartingDiscovery: @escaping () -> Void
        ) {
            _didUpdateDeviceList = didUpdateDeviceList
            _didStartDiscovery = didStartDiscovery
            _didHaveDiscoveredDeviceWhenStartingDiscovery = didHaveDiscoveredDeviceWhenStartingDiscovery

            super.init()
        }

        func didUpdateDeviceList() {
            _didUpdateDeviceList()
        }

        func didStartDiscovery(forDeviceCategory deviceCategory: String) {
            _didStartDiscovery(deviceCategory)
        }

        func didHaveDiscoveredDeviceWhenStartingDiscovery() {
            _didHaveDiscoveredDeviceWhenStartingDiscovery()
        }
    }
}

extension GoogleCastClient {
    class ConsoleLoggerDelegate: NSObject, GCKLoggerDelegate {
        func logMessage(_ message: String, at _: GCKLoggerLevel, fromFunction function: String, location: String) {
            print("\(location): \(function) - \(message)")
        }
    }

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
