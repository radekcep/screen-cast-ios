//
//  CMSampleBuffer+withCorrectedOrientation.swift
//  
//
//  Created by Radek Čep on 07.05.2022.
//

import Foundation
import ReplayKit

extension CMSampleBuffer {
    func withCorrectedOrientation(in ciContext: CIContext) -> CMSampleBuffer {
        let imagePropertyOrientation = self.imagePropertyOrientation

        var sampleBufferCopy: CMSampleBuffer?
        CMSampleBufferCreateCopy(
            allocator: kCFAllocatorDefault,
            sampleBuffer: self,
            sampleBufferOut: &sampleBufferCopy
        )

        guard let sampleBuffer = sampleBufferCopy else {
            print("CMSampleBuffer+withCorrectedOrientation - failed to copy sampleBufferCopy")
            return self
        }

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("CMSampleBuffer+withCorrectedOrientation - failed to create imageBuffer")
            return self
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
            print("CMSampleBuffer+withCorrectedOrientation - failed to create pixelBuffer")
            return self
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
            print("CMSampleBuffer+withCorrectedOrientation - failed to create formatDescription")
            return self
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
            print("CMSampleBuffer+withCorrectedOrientation - failed to create correctedSampleBuffer")
            print("CMSampleBuffer+withCorrectedOrientation - CMSampleBufferCreateReadyWithImageBuffer result: \(result)")
        }

        return correctedSampleBuffer
            ?? sampleBuffer
    }
}

private extension CMSampleBuffer {
    var imagePropertyOrientation: CGImagePropertyOrientation {
        let orientationAttachment = CMGetAttachment(
            self,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        ) as? NSNumber

        guard let orientationAttachment = orientationAttachment else {
            print("CMSampleBuffer+withCorrectedOrientation - failed to extract orientationAttachment")
            return .up
        }

        guard let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value) else {
            print("CMSampleBuffer+withCorrectedOrientation - unknown orientation")
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
