//
//  HLS+AssetWritter.swift
//  
//
//  Created by Radek Čep on 25.03.2022.
//

import AVFoundation
import Foundation
import ReplayKit

extension HLS {
    final class AssetWritter: NSObject {
        private let writer: AVAssetWriter
        private let videoInput: AVAssetWriterInput
        private let audioInput: AVAssetWriterInput

        private let outputData: (AVAssetWriter, Data, AVAssetSegmentType, AVAssetSegmentReport?) -> Void

        private var offset: CMTime?

        init(
            videoWidth: Int,
            videoHeight: Int,
            outputData: @escaping (AVAssetWriter, Data, AVAssetSegmentType, AVAssetSegmentReport?) -> Void
        ) {
            let fileType = UTType(AVFileType.mp4.rawValue)!
            writer = AVAssetWriter(contentType: fileType)
            writer.outputFileTypeProfile = .mpeg4AppleHLS
            writer.preferredOutputSegmentInterval = CMTime(seconds: 1, preferredTimescale: 1)
            writer.initialSegmentStartTime = CMTime.zero

            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: videoWidth,
                AVVideoHeightKey: videoHeight
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            writer.add(videoInput)

            var channelLayout = AudioChannelLayout.init()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_1_0
            let audioOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout<AudioChannelLayout>.size)
            ]
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            writer.add(audioInput)

            self.outputData = outputData
            super.init()

            writer.delegate = self
        }

        func writeBuffer(sampleBuffer: CMSampleBuffer, sampleBufferType: RPSampleBufferType) {
            if writer.status == .unknown {
                writer.startWriting()
                writer.startSession(atSourceTime: CMTime.zero)
            }

            if writer.status == .writing {
                if let offset = offset {
                    var copyBuffer: CMSampleBuffer?
                    var count: CMItemCount = 1
                    var info = CMSampleTimingInfo()

                    CMSampleBufferGetSampleTimingInfoArray(
                        sampleBuffer,
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
                        sampleBuffer: sampleBuffer,
                        sampleTimingEntryCount: 1,
                        sampleTimingArray: &info,
                        sampleBufferOut: &copyBuffer
                    )

                    guard let copyBuffer = copyBuffer else {
                        return
                    }

                    if sampleBufferType == .video, videoInput.isReadyForMoreMediaData {
                        videoInput.append(copyBuffer)
                    }

                    if sampleBufferType == .audioApp || sampleBufferType == .audioMic, audioInput.isReadyForMoreMediaData {
                        audioInput.append(copyBuffer)
                    }
                } else {
                    offset = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                }
            }
        }
    }
}

extension HLS.AssetWritter: AVAssetWriterDelegate {
    func assetWriter(
        _ writer: AVAssetWriter,
        didOutputSegmentData segmentData: Data,
        segmentType: AVAssetSegmentType,
        segmentReport: AVAssetSegmentReport?
    ) {
        outputData(writer, segmentData, segmentType, segmentReport)
    }
}
