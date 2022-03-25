//
//  StreamClientHLS.swift
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

private let playlistFilename = "playlist.m3u8"
private let segmentFilenamePrefix = "segment"

private let streamDirectoryURL: URL = FileManager.default
    .temporaryDirectory
    .appendingPathComponent("stream", isDirectory: true)

private let playlistFileURL: URL = streamDirectoryURL
    .appendingPathComponent(playlistFilename)

extension StreamClient {
    public static var hls: Self {
        var writer: HLS.AssetWritter?
        var httpServerTask: Task<(), Never>?
        var unusedStreamSegmentFileSuffix = 0

        return .init(
            startServer: { serverConfig in
                // Stop server if already running
                httpServerTask?.cancel()

                // Recreate streamDirectoryURL to remove any old files
                try? FileManager.default.removeItem(at: streamDirectoryURL)
                try? FileManager.default.createDirectory(at: streamDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                unusedStreamSegmentFileSuffix = 0

                writer = .init(
                    videoWidth: serverConfig.videoWidth,
                    videoHeight: serverConfig.videoHeight
                ) { _, segmentData, _, segmentReport in
                    let segmentExtension = segmentReport == nil ? "mp4" : "m4s"
                    let segmentName = "\(segmentFilenamePrefix)_\(unusedStreamSegmentFileSuffix).\(segmentExtension)"
                    let segmentDuration = segmentReport?.trackReports.first?.duration.seconds

                    let savedPlaylistContent = try? String(
                        contentsOf: playlistFileURL,
                        encoding: .utf8
                    )
                    let newPlaylistContent = HLS.playlist(
                        basedOn: savedPlaylistContent,
                        updatedWith: segmentName,
                        duration: segmentDuration
                    )

                    try? segmentData.write(to: streamDirectoryURL.appendingPathComponent(segmentName))
                    try? newPlaylistContent.data(using: .utf8)?.write(to: playlistFileURL)

                    unusedStreamSegmentFileSuffix += 1
                }

                httpServerTask = Task(priority: .high) {
                    // TODO: Implement proper error handling here
                    do {
                        _ = try await NIOTSListenerBootstrap(group: NIOTSEventLoopGroup())
                            .childChannelInitializer { channel in
                                channel.pipeline
                                    .configureHTTPServerPipeline(withPipeliningAssistance: true, withErrorHandling: true)
                                    .flatMap { channel.pipeline.addHandler(HTTP1ServerHandler()) }
                            }
                            .bind(host: serverConfig.address, port: serverConfig.port)
                            .get()
                    } catch {
                        print("🚨 Could not start the HLS server - \(error)")
                    }
                }
            },
            writeBuffer: {
                writer?.writeBuffer(sampleBuffer: $0, sampleBufferType: $1)
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

        if headData.uri.contains(playlistFilename) {
            writePlaylist(to: context)
        }
        if headData.uri.contains(segmentFilenamePrefix) {
            writeSegment(from: headData.uri, to: context)
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
