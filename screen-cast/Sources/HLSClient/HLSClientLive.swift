//
//  HLSClientLive.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import AVFoundation
import Foundation
import NIOCore
import NIOHTTP1
import NIOTransportServices
import NIO

private let streamDirectoryURL: URL = FileManager.default
    .temporaryDirectory
    .appendingPathComponent("stream", isDirectory: true)

private let playlistFileURL: URL = streamDirectoryURL
    .appendingPathComponent("playlist.m3u8")

extension HLSClient {
    public static var live: Self {
        var writer: AVAssetWriter!
        var offset: CMTime?
        var videoInput: AVAssetWriterInput!
        var assetWriterDelegate: AVAssetWriterDelegate!
        var httpServerTask: Task<(), Never>?
        var unusedStreamSegmentFileSuffix = 0

        return .init(
            startServer: {
                // Stop server if already running
                httpServerTask?.cancel()

                // Recreate streamDirectoryURL to remove any old files
                try? FileManager.default.removeItem(at: streamDirectoryURL)
                try? FileManager.default.createDirectory(at: streamDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                let fileType = UTType(AVFileType.mp4.rawValue)!
                writer = AVAssetWriter(contentType: fileType)
                writer.outputFileTypeProfile = .mpeg4AppleHLS
                writer.preferredOutputSegmentInterval = CMTime(seconds: 1, preferredTimescale: 1)
                writer.initialSegmentStartTime = CMTime.zero

                let videoOutputSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 1125,
                    AVVideoHeightKey: 2436
                ]

                videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
                videoInput.expectsMediaDataInRealTime = true
                writer.add(videoInput)

                offset = nil
                unusedStreamSegmentFileSuffix = 0

                assetWriterDelegate = AssetWriterDelegate { _, segmentData, _, segmentReport in
                    let segmentExtension = segmentReport == nil ? "mp4" : "m4s"
                    let segmentName = "segment_\(unusedStreamSegmentFileSuffix).\(segmentExtension)"
                    let segmentDuration = segmentReport?.trackReports.first?.duration.seconds

                    let savedPlaylistContent = try? String(contentsOf: playlistFileURL, encoding: .utf8)
                    let newPlaylistContent = playlist(basedOn: savedPlaylistContent, updatedWith: segmentName, duration: segmentDuration)

                    try? segmentData.write(to: streamDirectoryURL.appendingPathComponent(segmentName))
                    try? newPlaylistContent.data(using: .utf8)?.write(to: playlistFileURL)

                    unusedStreamSegmentFileSuffix += 1
                }
                writer.delegate = assetWriterDelegate

                httpServerTask = Task(priority: .high) {
                    _ = try? await NIOTSListenerBootstrap(group: NIOTSEventLoopGroup())
                        .childChannelInitializer { channel in
                            channel.pipeline
                                .configureHTTPServerPipeline(withPipeliningAssistance: true, withErrorHandling: true)
                                .flatMap { channel.pipeline.addHandler(HTTP1ServerHandler()) }
                        }
                        .bind(host: "192.168.1.162", port: 8099)
                        .get()
                }
            },
            writeBuffer: { sampleBuffer in
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
                        info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, offset)

                        CMSampleBufferCreateCopyWithNewTiming(
                            allocator: kCFAllocatorDefault,
                            sampleBuffer: sampleBuffer,
                            sampleTimingEntryCount: 1,
                            sampleTimingArray: &info,
                            sampleBufferOut: &copyBuffer
                        )

                        if let copyBuffer = copyBuffer, videoInput.isReadyForMoreMediaData {
                            videoInput.append(copyBuffer)
                        }
                    } else {
                        offset = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    }
                }
            }
        )
    }
}

private final class HTTP1ServerHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .head(let headData) = unwrapInboundIn(data) else {
            return
        }

        if headData.uri == "/" {
            writeIndexHTML(to: context)
        }
        if headData.uri.contains("playlist") {
            writePlaylist(to: context)
        }
        if headData.uri.contains("segment") {
            writeSegment(from: headData.uri, to: context)
        }
    }

    private func writeIndexHTML(to context: ChannelHandlerContext) {
        let indexFileURL = Bundle.module.url(forResource: "index", withExtension: "html")
        let indexFileContentType = "text/html; charset=utf-8"

        if let indexFileURL = indexFileURL {
            write(dataAt: indexFileURL, with: indexFileContentType, to: context)
        } else {
            writeNotFound(to: context)
        }
    }

    private func writePlaylist(to context: ChannelHandlerContext) {
        let playlistFileContentType = "application/vnd.apple.mpegurl"

        write(dataAt: playlistFileURL, with: playlistFileContentType, to: context)
    }

    private func writeSegment(from uri: String, to context: ChannelHandlerContext) {
        let segmentName = uri.replacingOccurrences(of: "/", with: "")
        let segmentExtension = segmentName.split(separator: ".").last.map(String.init)

        if let segmentExtension = segmentExtension {
            let segmentFileURL = streamDirectoryURL.appendingPathComponent(segmentName)
            let segmentFileContentType = "video/\(segmentExtension)"

            write(dataAt: segmentFileURL, with: segmentFileContentType, to: context)
        } else {
            writeNotFound(to: context)
        }
    }

    private func write(dataAt contentURL: URL, with contentType: String, to context: ChannelHandlerContext) {
        do {
            let data = try Data(contentsOf: contentURL)
            let buffer = context.channel.allocator.buffer(data: data)

            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Length", value: "\(data.count)")
            responseHeaders.add(name: "Content-Type", value: contentType)
            responseHeaders.add(name: "Access-Control-Allow-Origin", value: "*")
            responseHeaders.add(name: "Access-Control-Expose-Headers", value: "origin, range")

            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        } catch {
            writeNotFound(to: context)
        }
    }

    private func writeNotFound(to context: ChannelHandlerContext) {
        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .notFound)
        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}

private func playlist(basedOn previousPlaylistContent: String?, updatedWith newSegmentName: String, duration: Double?) -> String {
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

private extension String {
    /// Newline string "\n"
    static var newline: Self { "\n" }
}
