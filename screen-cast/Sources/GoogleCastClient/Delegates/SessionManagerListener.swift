//
//  SessionManagerListener.swift
//  
//
//  Created by Radek Čep on 16.01.2022.
//

import Foundation
import GoogleCast

// swiftlint:disable line_length
// swiftlint:disable identifier_name

class SessionManagerListener: NSObject, GCKSessionManagerListener {
    private let sessionManagerWillStartSession: (GCKSessionManager, GCKSession) -> Void
    private let sessionManagerDidStartSession: (GCKSessionManager, GCKSession) -> Void
    private let sessionManagerWillStartCastSession: (GCKSessionManager, GCKCastSession) -> Void
    private let sessionManagerDidStartCastSession: (GCKSessionManager, GCKCastSession) -> Void
    private let sessionManagerWillEndSession: (GCKSessionManager, GCKSession) -> Void
    private let sessionManagerDidEndSessionWithError: (GCKSessionManager, GCKSession, Error?) -> Void
    private let sessionManagerWillEndCastSession: (GCKSessionManager, GCKCastSession) -> Void
    private let sessionManagerDidEndCastSessionWithError: (GCKSessionManager, GCKSession, Error?) -> Void
    private let sessionManagerDidFailToStartSessionWithError: (GCKSessionManager, GCKSession, Error) -> Void
    private let sessionManagerDidFailToStartCastSessionWithError: (GCKSessionManager, GCKCastSession, Error) -> Void
    private let sessionManagerDidSuspendSessionWithReason: (GCKSessionManager, GCKSession, GCKConnectionSuspendReason) -> Void
    private let sessionManagerDidSuspendCastSessionWithReason: (GCKSessionManager, GCKCastSession, GCKConnectionSuspendReason) -> Void
    private let sessionManagerWillResumeSessionSession: (GCKSessionManager, GCKSession) -> Void
    private let sessionManagerDidResumeSessionSession: (GCKSessionManager, GCKSession) -> Void
    private let sessionManagerWillResumeCastSessionSession: (GCKSessionManager, GCKCastSession) -> Void
    private let sessionManagerDidResumeCastSessionSession: (GCKSessionManager, GCKCastSession) -> Void
    private let sessionManagerSessionDidUpdate: (GCKSessionManager, GCKSession, GCKDevice) -> Void
    private let sessionManagerSessionDidReceiveDeviceVolume: (GCKSessionManager, GCKSession, Float, _ muted: Bool) -> Void
    private let sessionManagerCastSessionSessionDidReceiveDeviceVolume: (GCKSessionManager, GCKCastSession, Float, _ muted: Bool) -> Void
    private let sessionManagerSessionDidReceiveDeviceStatus: (GCKSessionManager, GCKSession, String?) -> Void
    private let sessionManagerCastSessionSessionDidReceiveDeviceStatusStatusText: (GCKSessionManager, GCKCastSession, String?) -> Void
    private let sessionManagerDidUpdateDefaultSessionOptionsForDeviceCategory: (GCKSessionManager, String) -> Void

    init(
        sessionManagerWillStartSession: @escaping (GCKSessionManager, GCKSession) -> Void = { _, _ in },
        sessionManagerDidStartSession: @escaping (GCKSessionManager, GCKSession) -> Void = { _, _ in },
        sessionManagerWillStartCastSession: @escaping (GCKSessionManager, GCKCastSession) -> Void = { _, _ in },
        sessionManagerDidStartCastSession: @escaping (GCKSessionManager, GCKCastSession) -> Void = { _, _ in },
        sessionManagerWillEndSession: @escaping (GCKSessionManager, GCKSession) -> Void = { _, _ in },
        sessionManagerDidEndSessionWithError: @escaping (GCKSessionManager, GCKSession, Error?) -> Void = { _, _, _ in },
        sessionManagerWillEndCastSession: @escaping (GCKSessionManager, GCKCastSession) -> Void = { _, _ in },
        sessionManagerDidEndCastSessionWithError: @escaping (GCKSessionManager, GCKSession, Error?) -> Void = { _, _, _ in },
        sessionManagerDidFailToStartSessionWithError: @escaping (GCKSessionManager, GCKSession, Error) -> Void = { _, _, _ in },
        sessionManagerDidFailToStartCastSessionWithError: @escaping (GCKSessionManager, GCKCastSession, Error) -> Void = { _, _, _ in },
        sessionManagerDidSuspendSessionWithReason: @escaping (GCKSessionManager, GCKSession, GCKConnectionSuspendReason) -> Void = { _, _, _ in },
        sessionManagerDidSuspendCastSessionWithReason: @escaping (GCKSessionManager, GCKCastSession, GCKConnectionSuspendReason) -> Void = { _, _, _ in },
        sessionManagerWillResumeSessionSession: @escaping (GCKSessionManager, GCKSession) -> Void = { _, _ in },
        sessionManagerDidResumeSessionSession: @escaping (GCKSessionManager, GCKSession) -> Void = { _, _ in },
        sessionManagerWillResumeCastSessionSession: @escaping (GCKSessionManager, GCKCastSession) -> Void = { _, _ in },
        sessionManagerDidResumeCastSessionSession: @escaping (GCKSessionManager, GCKCastSession) -> Void = { _, _ in },
        sessionManagerSessionDidUpdate: @escaping (GCKSessionManager, GCKSession, GCKDevice) -> Void = { _, _, _ in },
        sessionManagerSessionDidReceiveDeviceVolume: @escaping (GCKSessionManager, GCKSession, Float, _ muted: Bool) -> Void = { _, _, _, _ in },
        sessionManagerCastSessionSessionDidReceiveDeviceVolume: @escaping (GCKSessionManager, GCKCastSession, Float, _ muted: Bool) -> Void = { _, _, _, _ in },
        sessionManagerSessionDidReceiveDeviceStatus: @escaping (GCKSessionManager, GCKSession, String?) -> Void = { _, _, _ in },
        sessionManagerCastSessionSessionDidReceiveDeviceStatusStatusText: @escaping (GCKSessionManager, GCKCastSession, String?) -> Void = { _, _, _ in },
        sessionManagerDidUpdateDefaultSessionOptionsForDeviceCategory: @escaping (GCKSessionManager, String) -> Void = { _, _ in }
    ) {
        self.sessionManagerWillStartSession = sessionManagerWillStartSession
        self.sessionManagerDidStartSession = sessionManagerDidStartSession
        self.sessionManagerWillStartCastSession = sessionManagerWillStartCastSession
        self.sessionManagerDidStartCastSession = sessionManagerDidStartCastSession
        self.sessionManagerWillEndSession = sessionManagerWillEndSession
        self.sessionManagerDidEndSessionWithError = sessionManagerDidEndSessionWithError
        self.sessionManagerWillEndCastSession = sessionManagerWillEndCastSession
        self.sessionManagerDidEndCastSessionWithError = sessionManagerDidEndCastSessionWithError
        self.sessionManagerDidFailToStartSessionWithError = sessionManagerDidFailToStartSessionWithError
        self.sessionManagerDidFailToStartCastSessionWithError = sessionManagerDidFailToStartCastSessionWithError
        self.sessionManagerDidSuspendSessionWithReason = sessionManagerDidSuspendSessionWithReason
        self.sessionManagerDidSuspendCastSessionWithReason = sessionManagerDidSuspendCastSessionWithReason
        self.sessionManagerWillResumeSessionSession = sessionManagerWillResumeSessionSession
        self.sessionManagerDidResumeSessionSession = sessionManagerDidResumeSessionSession
        self.sessionManagerWillResumeCastSessionSession = sessionManagerWillResumeCastSessionSession
        self.sessionManagerDidResumeCastSessionSession = sessionManagerDidResumeCastSessionSession
        self.sessionManagerSessionDidUpdate = sessionManagerSessionDidUpdate
        self.sessionManagerSessionDidReceiveDeviceVolume = sessionManagerSessionDidReceiveDeviceVolume
        self.sessionManagerCastSessionSessionDidReceiveDeviceVolume = sessionManagerCastSessionSessionDidReceiveDeviceVolume
        self.sessionManagerSessionDidReceiveDeviceStatus = sessionManagerSessionDidReceiveDeviceStatus
        self.sessionManagerCastSessionSessionDidReceiveDeviceStatusStatusText = sessionManagerCastSessionSessionDidReceiveDeviceStatusStatusText
        self.sessionManagerDidUpdateDefaultSessionOptionsForDeviceCategory = sessionManagerDidUpdateDefaultSessionOptionsForDeviceCategory

        super.init()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        sessionManagerWillStartSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        sessionManagerDidStartSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        sessionManagerWillStartCastSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        sessionManagerDidStartCastSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        sessionManagerWillEndSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        sessionManagerDidEndSessionWithError(sessionManager, session, error)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        sessionManagerWillEndCastSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        sessionManagerDidEndCastSessionWithError(sessionManager, session, error)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        sessionManagerDidFailToStartSessionWithError(sessionManager, session, error)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        sessionManagerDidFailToStartCastSessionWithError(sessionManager, session, error)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
        sessionManagerDidSuspendSessionWithReason(sessionManager, session, reason)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        sessionManagerDidSuspendCastSessionWithReason(sessionManager, session, reason)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        sessionManagerWillResumeSessionSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        sessionManagerDidResumeSessionSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willResumeCastSession session: GCKCastSession) {
        sessionManagerWillResumeCastSessionSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        sessionManagerDidResumeCastSessionSession(sessionManager, session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        sessionManagerSessionDidUpdate(sessionManager, session, device)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        sessionManagerSessionDidReceiveDeviceVolume(sessionManager, session, volume, muted)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        sessionManagerCastSessionSessionDidReceiveDeviceVolume(sessionManager, session, volume, muted)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
        sessionManagerSessionDidReceiveDeviceStatus(sessionManager, session, statusText)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceStatus statusText: String?) {
        sessionManagerCastSessionSessionDidReceiveDeviceStatusStatusText(sessionManager, session, statusText)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didUpdateDefaultSessionOptionsForDeviceCategory category: String) {
        sessionManagerDidUpdateDefaultSessionOptionsForDeviceCategory(sessionManager, category)
    }
}

// swiftlint:enable line_length
// swiftlint:enable identifier_name
