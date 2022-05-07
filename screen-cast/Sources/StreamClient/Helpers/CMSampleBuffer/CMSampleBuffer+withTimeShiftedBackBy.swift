//
//  CMSampleBuffer+withTimeShiftedBackBy.swift
//  
//
//  Created by Radek Čep on 07.05.2022.
//

import Foundation
import ReplayKit

extension CMSampleBuffer {
    func withTimeShiftedBackBy(offset: CMTime) -> CMSampleBuffer? {
        var copyBuffer: CMSampleBuffer?
        var count: CMItemCount = 1
        var info = CMSampleTimingInfo()

        CMSampleBufferGetSampleTimingInfoArray(
            self,
            entryCount: count,
            arrayToFill: &info,
            entriesNeededOut: &count
        )

        info.presentationTimeStamp = CMTimeSubtract(
            info.presentationTimeStamp,
            offset
        )

        CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: self,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &info,
            sampleBufferOut: &copyBuffer
        )

        return copyBuffer
    }
}
