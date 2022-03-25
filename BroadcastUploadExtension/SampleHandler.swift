//
//  SampleHandler.swift
//  BroadcastUploadExtension
//
//  Created by Radek Čep on 19.01.2022.
//

import ComposableArchitecture
import ExtensionCore
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    lazy var store = Store(
        initialState: ExtensionState(),
        reducer: extensionReducer,
        environment: ExtensionEnvironment(
            finishBroadcastWithError: { [weak self] error in self?.finishBroadcastWithError(error) },
            googleCastClient: .live,
            settingsClient: .live,
            streamClient: .hls
        )
    )

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        sendOnMain(.broadcastStarted)
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        sendOnMain(.processSampleBuffer(sampleBuffer, sampleBufferType))
    }
}

private extension SampleHandler {
    /// Sends the `action` to the Store on the main thread
    func sendOnMain(_ action: ExtensionAction) {
        // Store is not thread safe and all actions must be dispatched on the main thread.
        // RPBroadcastSampleHandler on the other hand runs on a background thread by default.
        DispatchQueue.main.async {
            ViewStore(self.store).send(action)
        }
    }
}
