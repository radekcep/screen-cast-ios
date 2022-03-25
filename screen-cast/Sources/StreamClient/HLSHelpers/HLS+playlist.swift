//
//  HLS+playlist.swift
//  
//
//  Created by Radek Čep on 25.03.2022.
//

import Foundation

extension HLS {
    static func playlist(basedOn previousPlaylistContent: String?, updatedWith newSegmentName: String, duration: Double?) -> String {
        guard let previousPlaylistContent = previousPlaylistContent, !previousPlaylistContent.isEmpty else {
            // Generate new playlist header
            return [
                "#EXTM3U",
                "#EXT-X-TARGETDURATION:\(1)",
                "#EXT-X-VERSION:7",
                "#EXT-X-MEDIA-SEQUENCE:1",
                "#EXT-X-MAP:URI=\"\(newSegmentName)\""
            ]
                .joined(separator: .newline)
                .appending(String.newline)
        }

        guard let duration = duration else {
            // Cannot add a segment without a valid duration
            return previousPlaylistContent
        }

        let formattedDuration = String(format: "%1.5f", duration)
        let newSegmentString = [
            "#EXTINF:\(formattedDuration),",
            "\(newSegmentName)"
        ]
            .joined(separator: .newline)

        return previousPlaylistContent
            .appending(newSegmentString)
            .appending(String.newline)
    }
}

private extension String {
    /// Newline string `\n`
    static var newline: Self { "\n" }
}
