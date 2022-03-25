//
//  DiscoveryManagerListener.swift
//  
//
//  Created by Radek Čep on 16.01.2022.
//

import Foundation
import GoogleCast

// swiftlint:disable identifier_name

class DiscoveryManagerListener: NSObject, GCKDiscoveryManagerListener {
    private let _didUpdateDeviceList: () -> Void
    private let _didStartDiscovery: (_ deviceCategory: String) -> Void
    private let _didHaveDiscoveredDeviceWhenStartingDiscovery: () -> Void

    init(
        didUpdateDeviceList: @escaping () -> Void = { },
        didStartDiscovery: @escaping (_ deviceCategory: String) -> Void = { _ in },
        didHaveDiscoveredDeviceWhenStartingDiscovery: @escaping () -> Void = { }
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

// swiftlint:enable identifier_name
