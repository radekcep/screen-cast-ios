//
//  GoogleCastClient.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import ComposableArchitecture
import Foundation
import GoogleCast

extension GoogleCastClient {
    public static var live: Self {
       let delegate = LoggerDelegate()

        return .init(
            receivers: {
                setupLogger(with: delegate)
                GCKCastContext.setSharedInstanceWith(.init())

                let manager = GCKCastContext.sharedInstance().discoveryManager
                // GCKDiscoveryManager.initialize()

                manager.add(DiscoveryManagerListener())
                manager.startDiscovery()

                return .none
            }
        )
    }
}

private extension GoogleCastClient {
    class DiscoveryManagerListener: NSObject, GCKDiscoveryManagerListener {
        func didUpdateDeviceList() {
            print(#function)
        }

        func didStartDiscovery(forDeviceCategory deviceCategory: String) {
            print(#function)
        }

        func didHaveDiscoveredDeviceWhenStartingDiscovery() {
            print(#function)
        }
    }
}

private extension GoogleCastClient {
    class LoggerDelegate: NSObject, GCKLoggerDelegate {
        deinit {
            print("Oh no")
        }

        func logMessage(_ message: String, at _: GCKLoggerLevel, fromFunction function: String, location: String) {
            print("\(location): \(function) - \(message)")
        }
    }

    static func setupLogger(with delegate: GCKLoggerDelegate) {
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
