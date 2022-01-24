//
//  AssetWriterDelegate.swift
//  
//
//  Created by Radek Čep on 24.01.2022.
//

import AVFoundation
import Foundation

// swiftlint:disable line_length
// swiftlint:disable identifier_name

class AssetWriterDelegate: NSObject, AVAssetWriterDelegate {
    private let assetWriterDidOutputSegmentDataSegmentTypeSegmentReport: (AVAssetWriter, Data, AVAssetSegmentType, AVAssetSegmentReport?) -> Void

    init(
        assetWriterDidOutputSegmentDataSegmentTypeSegmentReport: @escaping (AVAssetWriter, Data, AVAssetSegmentType, AVAssetSegmentReport?) -> Void
    ) {
        self.assetWriterDidOutputSegmentDataSegmentTypeSegmentReport = assetWriterDidOutputSegmentDataSegmentTypeSegmentReport
        super.init()
    }

    func assetWriter(
        _ writer: AVAssetWriter,
        didOutputSegmentData segmentData: Data,
        segmentType: AVAssetSegmentType,
        segmentReport: AVAssetSegmentReport?
    ) {
        assetWriterDidOutputSegmentDataSegmentTypeSegmentReport(writer, segmentData, segmentType, segmentReport)
    }
}

// swiftlint:enable line_length
// swiftlint:enable identifier_name
