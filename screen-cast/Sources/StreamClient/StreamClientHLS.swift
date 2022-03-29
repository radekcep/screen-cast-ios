//
//  StreamClientHLS.swift
//  
//
//  Created by Radek Čep on 19.01.2022.
//

import AVFoundation
import Combine
import Foundation
import NIO
import NIOCore
import NIOHTTP1
import NIOTransportServices

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
        var unusedStreamSegmentFileSuffix = 0
        let backgroundQueue = DispatchQueue(label: "StreamClient.ServerQueue")

        var openedChannel: Channel?

        return .init(
            startServer: { serverConfig in
                Deferred {
                    Future<Void, StreamClient.Error> { observer in
                        do {
                            // Stop any previous server from writing new buffers
                            writer = nil

                            // Stop the previously running server, if any
                            try openedChannel?.close().wait()

                            // Recreate streamDirectoryURL to remove any old files
                            try? FileManager.default.removeItem(at: streamDirectoryURL)
                            try? FileManager.default.createDirectory(at: streamDirectoryURL, withIntermediateDirectories: true)

                            // Reset segments index
                            unusedStreamSegmentFileSuffix = 0

                            // Create a new writter
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

                            print("StreamClient - Clean up complete")
                            observer(.success(()))

                        } catch {
                            print("StreamClient - Failed to clean up")
                            observer(.failure(.unableToCloseRunningServer(error)))
                        }
                    }
                }
                .flatMap {
                    Future<String, StreamClient.Error> { observer in
                        guard let wifiIPAddress = Network.wifiIPAddress() else {
                            print("StreamClient - Could not obtain WiFi address")
                            observer(.failure(.wifiAddressUnavailable))
                            return
                        }

                        print("StreamClient - Obtained WiFi address: \(wifiIPAddress)")
                        observer(.success(wifiIPAddress))
                    }
                }
                .flatMap { wifiIPAddress in
                    // Start a new server
                    Future<StreamClient.Action, StreamClient.Error> { observer in
                        print("StreamClient - Starting up server...")

                        do {
                            openedChannel = try NIOTSListenerBootstrap(group: NIOTSEventLoopGroup())
                                .childChannelInitializer { channel in
                                    channel.pipeline
                                        .configureHTTPServerPipeline(withPipeliningAssistance: true, withErrorHandling: true)
                                        .flatMap { channel.pipeline.addHandler(HTTP1ServerHandler()) }
                                }
                                .bind(host: wifiIPAddress, port: 0)
                                .wait()
                        } catch {
                            print("StreamClient - Unable to start up server: \(error)")
                            observer(.failure(.unableToStartServer(error)))
                            return
                        }

                        if let ipAddress = openedChannel?.localAddress?.ipAddress,
                            let port = openedChannel?.localAddress?.port,
                            let url = URL(string: "http://\(ipAddress):\(port)/\(playlistFilename)") {

                            print("StreamClient - Server up: \(url)")
                            observer(.success(.serverRunning(url)))
                        } else {

                            print("StreamClient - Invalid url")
                            observer(.failure(.invalidIPAddress))
                        }
                    }
                }
                .subscribe(on: backgroundQueue)
                .eraseToEffect()
            },
            writeBuffer: {
                writer?.writeBuffer($0, ofType: $1)
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
