//
//  GoogleCastClient.swift
//  
//
//  Created by Radek Čep on 14.01.2022.
//

import Combine
import ComposableArchitecture
import Foundation
import GoogleCast

extension GoogleCastClient {
    public static var live: Self {
        var discoveryListener: GCKDiscoveryManagerListener?

        return .init(
            startDiscovery: {
                let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
                let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)

                GCKCastContext.setSharedInstanceWith(options)
                let discoveryManager = GCKCastContext.sharedInstance().discoveryManager

                return .run { subscriber in
                    discoveryListener = DiscoveryManagerListener(
                        didUpdateDeviceList: {
                            let receivers = (0..<discoveryManager.deviceCount)
                                .map(discoveryManager.device(at:))
                                .map(GoogleCastReceiver.init)

                            subscriber.send(.discovered(receivers: receivers))
                        },
                        didStartDiscovery: { _ in },
                        didHaveDiscoveredDeviceWhenStartingDiscovery: { }
                    )

                    discoveryManager.add(discoveryListener!)
                    discoveryManager.startDiscovery()

                    return AnyCancellable {
                        discoveryManager.remove(discoveryListener!)
                        discoveryManager.stopDiscovery()
                    }
                }
            }
        )
    }
}
