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
        var requestDelegate: RequestDelegate?

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
            },
            startSession: { googleCastReceiver in
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
                        },
                        sessionManagerDidResumeSessionSession: { _, _ in
                            subscriber.send(.sessionStarted(googleCastReceiver.id))
                        }
                    )

                    castContext.sessionManager.add(sessionListener!)
                    castContext.sessionManager.startSession(with: gckDevice)

                    return AnyCancellable {
                        castContext.sessionManager.remove(sessionListener!)
                        castContext.sessionManager.endSession()
                    }
                }
            },
            loadMedia: { mediaConfig in
                .run { subscriber in
                    let mediaInfoBuilder = GCKMediaInformationBuilder()
                    mediaInfoBuilder.contentURL = mediaConfig.url
                    mediaInfoBuilder.hlsVideoSegmentFormat = .FMP4

                    let mediaInformation = mediaInfoBuilder.build()
                    let request = castContext.sessionManager.currentSession?.remoteMediaClient?.loadMedia(mediaInformation)

                    print("GoogleCastClient - Requesting a connection to: \(mediaConfig.url)")

                    // TODO: Handle media reques
                    // NOTE: `requestDidComplete` is called after the request is accepted and the stream starts.
                    requestDelegate = RequestDelegate(
                        requestDidComplete: { _ in
                            print("GoogleCastClient - requestDidComplete \(request.debugDescription)")
                            //                                    subscriber.send(.requestCompleted)
                            //                                    subscriber.send(completion: .finished)
                        },
                        requestDidFailWithError: { _, error in
                            print("GoogleCastClient - requestDidFailWithError \(request.debugDescription) \(error)")
                            //                                    subscriber.send(completion: .failure(.unableToLoadMedia))
                        },
                        requestDidAbortWithAbortReason: { _, error in
                            print("GoogleCastClient - requestDidAbortWithAbortReason \(request.debugDescription) \(error)")
                            //                                    subscriber.send(completion: .failure(.mediaRequestAborted))
                        }
                    )
                    request?.delegate = requestDelegate

                    return AnyCancellable {}
                }
            }
        )
    }
}
