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
        var sessionListener: GCKSessionManagerListener?

        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)

        GCKCastContext.setSharedInstanceWith(options)
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        let sessionManager = GCKCastContext.sharedInstance().sessionManager

        return .init(
            startDiscovery: {
                .run { subscriber in
                    discoveryListener = DiscoveryManagerListener(
                        didUpdateDeviceList: {
                            let receivers = (0..<discoveryManager.deviceCount)
                                .map(discoveryManager.device(at:))
                                .map(GoogleCastReceiver.init)

                            subscriber.send(.discovered(receivers: receivers))
                        }
                    )

                    discoveryManager.add(discoveryListener!)
                    discoveryManager.startDiscovery()

                    return AnyCancellable {
                        discoveryManager.remove(discoveryListener!)
                        discoveryManager.stopDiscovery()
                    }
                }
            }, startSession: { googleCastReceiver in
                .run { subscriber in
                    guard let gckDevice = discoveryManager.device(withUniqueID: googleCastReceiver.id) else {
                        subscriber.send(completion: .failure(.deviceUnavailable))
                        return AnyCancellable { }
                    }

                    sessionListener = SessionManagerListener(
                        sessionManagerDidStartSession: { _, _ in
                            subscriber.send(.sessionStarted(googleCastReceiver.id))
                        },
                        sessionManagerDidEndSessionWithError: { _, _, error in
                            subscriber.send(.sessionEnded)

                            if error != nil {
                                subscriber.send(completion: .failure(.sessionInterrupted))
                            } else {
                                subscriber.send(completion: .finished)
                            }
                        },
                        sessionManagerDidFailToStartSessionWithError: { _, _, _ in
                            subscriber.send(completion: .failure(.unableToStartSession))
                        }
                    )

                    sessionManager.add(sessionListener!)
                    sessionManager.startSession(with: gckDevice)

                    return AnyCancellable {
                        sessionManager.remove(sessionListener!)
                        sessionManager.endSession()
                    }
                }
            }
        )
    }
}
