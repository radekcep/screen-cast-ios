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
        // swiftlint:disable:next nesting
        typealias OutputDataCallback = (AVAssetWriter, Data, AVAssetSegmentType, AVAssetSegmentReport?) -> Void

        private let ciContext: CIContext
        private let writer: AVAssetWriter
        private let audioInput: AVAssetWriterInput
        private let videoInput: AVAssetWriterInput
        private let frameRateStabiliser: CMSampleBuffer.FrameRateStabiliser
        private let outputData: OutputDataCallback

        private var initialPresentationTimeStamp: CMTime?

        init(
            videoWidth: Int,
            videoHeight: Int,
            outputData: @escaping OutputDataCallback
        ) {
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                ciContext = CIContext(mtlDevice: metalDevice)
            } else {
                ciContext = CIContext(options: nil)
            }

            let fileType = UTType(AVFileType.mp4.rawValue)!
            writer = AVAssetWriter(contentType: fileType)
            writer.outputFileTypeProfile = .mpeg4AppleHLS
            writer.preferredOutputSegmentInterval = CMTimeMake(value: 1, timescale: 2)
            writer.initialSegmentStartTime = CMTime.zero

            var channelLayout = AudioChannelLayout.init()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_2_0
            let audioOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout<AudioChannelLayout>.size)
            ]
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            writer.add(audioInput)

            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
                AVVideoWidthKey: videoWidth,
                AVVideoHeightKey: videoHeight
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            writer.add(videoInput)

            frameRateStabiliser = .init()
            self.outputData = outputData

            super.init()

            frameRateStabiliser.output = { [weak self] sampleBuffer in
                guard let self = self else { return }
                self.writeBuffer(sampleBuffer, into: self.videoInput)
            }

            writer.delegate = self
        }

        func writeBuffer(_ sampleBuffer: CMSampleBuffer, ofType sampleBufferType: RPSampleBufferType) {
            initialPresentationTimeStamp = initialPresentationTimeStamp
                ?? CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            guard let initialPresentationTimeStamp = initialPresentationTimeStamp else {
                return
            }

            if writer.status == .unknown {
                writer.startWriting()
                writer.startSession(atSourceTime: initialPresentationTimeStamp)
            }

            guard writer.status == .writing else {
                return
            }

            if sampleBufferType == .video {
                let sampleBuffer = sampleBuffer.withCorrectedOrientation(in: ciContext)
                frameRateStabiliser.writeBuffer(sampleBuffer)
            }

            if sampleBufferType == .audioApp {
                writeBuffer(sampleBuffer, into: audioInput)
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

private extension HLS.AssetWritter {
    func writeBuffer(_ sampleBuffer: CMSampleBuffer, into assetWriterInput: AVAssetWriterInput) {
        guard assetWriterInput.isReadyForMoreMediaData else {
            return
        }

        assetWriterInput.append(sampleBuffer)
    }
}
