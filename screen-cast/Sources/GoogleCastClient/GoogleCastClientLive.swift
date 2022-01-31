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
        var castContext: GCKCastContext!
        var discoveryListener: GCKDiscoveryManagerListener?
        var sessionListener: GCKSessionManagerListener?

        return .init(
            startDiscovery: {
                .run { subscriber in
                    if castContext == nil {
                        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
                        let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
                        GCKCastContext.setSharedInstanceWith(options)
                        castContext = GCKCastContext.sharedInstance()
                    }

                    discoveryListener = DiscoveryManagerListener(
                        didUpdateDeviceList: {
                            let receivers = (0..<castContext.discoveryManager.deviceCount)
                                .map(castContext.discoveryManager.device(at:))
                                .map(GoogleCastReceiver.init)

                            subscriber.send(.discovered(receivers: receivers))
                        }
                    )

                    castContext.discoveryManager.add(discoveryListener!)
                    castContext.discoveryManager.startDiscovery()

                    return AnyCancellable {
                        castContext.discoveryManager.remove(discoveryListener!)
                        castContext.discoveryManager.stopDiscovery()
                    }
                }
            }, startSession: { googleCastReceiver in
                .run { subscriber in
                    guard let gckDevice = castContext.discoveryManager.device(withUniqueID: googleCastReceiver.id.rawValue) else {
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

                    castContext.sessionManager.add(sessionListener!)
                    castContext.sessionManager.startSession(with: gckDevice)

                    return AnyCancellable {
                        castContext.sessionManager.remove(sessionListener!)
                        castContext.sessionManager.endSession()
                    }
                }
            }
        )
    }
}
