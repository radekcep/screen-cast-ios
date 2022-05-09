//
//  CMSampleBuffer+FrameRateStabiliser.swift
//  
//
//  Created by Radek Čep on 07.05.2022.
//

import Combine
import Foundation
import ReplayKit

extension CMSampleBuffer {
    final class FrameRateStabiliser {
        private var droppedFirstLink: Bool = false
        private var feedbackSeconds: Double = .zero
        private var offset: Double = .zero
        private var initialPresentationTimeStamp: CMTime?
        private var latestSampleBuffer: CMSampleBuffer?
        private var displayLink: CADisplayLink?

        var output: ((CMSampleBuffer) -> Void)?

        init() {
            displayLink = CADisplayLink(target: self, selector: #selector(linkTriggered))
            displayLink?.add(to: .main, forMode: .default)
        }

        deinit {
            displayLink?.invalidate()
        }

        func writeBuffer(_ sampleBuffer: CMSampleBuffer) {
            var copyBuffer: CMSampleBuffer?
            CMSampleBufferCreateCopy(
                allocator: kCFAllocatorDefault,
                sampleBuffer: sampleBuffer,
                sampleBufferOut: &copyBuffer
            )

            latestSampleBuffer = copyBuffer
        }
    }
}

private extension CMSampleBuffer.FrameRateStabiliser {
    @objc func linkTriggered(displayLink: CADisplayLink) {
        // It is necessary to drop the first link, since the link duration is not reported correctly the first time.
        guard droppedFirstLink else {
            droppedFirstLink = true
            return
        }

        // No buffer available yet.
        guard let sampleBuffer = latestSampleBuffer else {
            return
        }

        // Save the initialPresentationTimeStamp
        initialPresentationTimeStamp = initialPresentationTimeStamp
            ?? CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard let initialPresentationTimeStamp = initialPresentationTimeStamp else {
            return
        }

        // Update next offset. The feedback loop is used to prevent frames lagging behind their intended time stamps.
        // This is a temporary solution and should be refactored in the future version.
        let offset = self.offset
        self.offset += displayLink.duration - self.feedbackSeconds / 10

        var copyBuffer: CMSampleBuffer?
        var entryCount: CMItemCount = 1
        var info = CMSampleTimingInfo()

        CMSampleBufferGetSampleTimingInfoArray(
            sampleBuffer,
            entryCount: entryCount,
            arrayToFill: &info,
            entriesNeededOut: &entryCount
        )

        let intendedBufferTimeStampSeconds = CMTimeGetSeconds(info.presentationTimeStamp)
        let proposedBufferTimeStampSeconds = CMTimeGetSeconds(initialPresentationTimeStamp) + offset
        let bufferTimeStampSecondsDifference = proposedBufferTimeStampSeconds - intendedBufferTimeStampSeconds

        // Correct only negative difference where the display link is lagging behind the proposed time stamp.
        // Positive difference means that a buffer is repeated, which is desired to prevent frame drops.
        feedbackSeconds = min(bufferTimeStampSecondsDifference, .zero)

        info.presentationTimeStamp = CMTimeMakeWithSeconds(
            proposedBufferTimeStampSeconds,
            preferredTimescale: initialPresentationTimeStamp.timescale
        )

        CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &info,
            sampleBufferOut: &copyBuffer
        )

        copyBuffer.map { output?($0) }
    }
}
