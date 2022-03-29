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
        private let outputData: OutputDataCallback

        private var audioOffset: CMTime?
        private var videoOffset: CMTime?

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
            writer.preferredOutputSegmentInterval = CMTime(seconds: 1, preferredTimescale: 1)
            writer.initialSegmentStartTime = CMTime.zero

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

            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
                AVVideoWidthKey: videoWidth,
                AVVideoHeightKey: videoHeight
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            writer.add(videoInput)

            self.outputData = outputData
            super.init()

            writer.delegate = self
        }

        func writeBuffer(_ sampleBuffer: CMSampleBuffer, ofType sampleBufferType: RPSampleBufferType) {
            if writer.status == .unknown {
                writer.startWriting()
                writer.startSession(atSourceTime: CMTime.zero)
            }

            guard writer.status == .writing else {
                return
            }

            if sampleBufferType == .video {
                let sampleBuffer = sampleBufferWithCorrectedOrientation(sampleBuffer)
                writeBuffer(sampleBuffer, with: &videoOffset, into: videoInput)
            }

            if sampleBufferType == .audioApp || sampleBufferType == .audioMic {
                writeBuffer(sampleBuffer, with: &audioOffset, into: audioInput)
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
    func sampleBufferWihCorrectedTiming(_ sampleBuffer: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer? {
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

        return copyBuffer
    }

    func writeBuffer(_ sampleBuffer: CMSampleBuffer, with offset: inout CMTime?, into assetWriterInput: AVAssetWriterInput) {
        guard let offset = offset else {
            offset = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            return
        }

        guard assetWriterInput.isReadyForMoreMediaData else {
            return
        }

        guard let bufferCopy = sampleBufferWihCorrectedTiming(sampleBuffer, offset: offset) else {
            return
        }

        assetWriterInput.append(bufferCopy)
    }
}

private extension HLS.AssetWritter {
    func imagePropertyOrientation(in sampleBuffer: CMSampleBuffer) -> CGImagePropertyOrientation {
        let orientationAttachment = CMGetAttachment(
            sampleBuffer,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        ) as? NSNumber

        guard let orientationAttachment = orientationAttachment else {
            print("HLS.AssetWritter - failed to extract orientationAttachment")
            return .up
        }

        guard let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) else {
            print("HLS.AssetWritter - unknown orientation")
            return .up
        }

        switch orientation {
        case .up, .upMirrored:
            return .up
        case .down, .downMirrored:
            return .down
        case .left, .leftMirrored:
            return .right
        case .right, .rightMirrored:
            return .left
        }
    }

    func sampleBufferWithCorrectedOrientation(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        let imagePropertyOrientation = imagePropertyOrientation(in: sampleBuffer)

        var sampleBufferCopy: CMSampleBuffer?
        CMSampleBufferCreateCopy(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleBufferOut: &sampleBufferCopy
        )

        guard let sampleBuffer = sampleBufferCopy else {
            print("HLS.AssetWritter - failed to copy sampleBufferCopy")
            return sampleBuffer
        }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("HLS.AssetWritter - failed to create imageBuffer")
            return sampleBuffer
        }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            imagePropertyOrientation.isLandscape ? CVPixelBufferGetWidth(imageBuffer) : CVPixelBufferGetHeight(imageBuffer),
            imagePropertyOrientation.isLandscape ? CVPixelBufferGetHeight(imageBuffer) : CVPixelBufferGetWidth(imageBuffer),
            CVPixelBufferGetPixelFormatType(imageBuffer),
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer
        )

        guard let pixelBuffer = pixelBuffer else {
            print("HLS.AssetWritter - failed to create pixelBuffer")
            return sampleBuffer
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer).oriented(imagePropertyOrientation)
        autoreleasepool { ciContext.render(ciImage, to: pixelBuffer) }

        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        var timingInfo = CMSampleTimingInfo(
            duration: CMSampleBufferGetDuration(sampleBuffer),
            presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
            decodeTimeStamp: CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
        )

        guard let formatDescription = formatDescription else {
            print("HLS.AssetWritter - failed to create formatDescription")
            return sampleBuffer
        }

        var correctedSampleBuffer: CMSampleBuffer?
        let result = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &correctedSampleBuffer
        )

        if correctedSampleBuffer == nil {
            print("HLS.AssetWritter - failed to create correctedSampleBuffer")
            print("HLS.AssetWritter - CMSampleBufferCreateReadyWithImageBuffer result: \(result)")
        }

        return correctedSampleBuffer
            ?? sampleBuffer
    }
}

private extension CGImagePropertyOrientation {
    var isLandscape: Bool {
        switch self {
        case .up, .upMirrored, .down, .downMirrored:
            return true
        case .left, .leftMirrored, .right, .rightMirrored:
            return false
        }
    }
}
