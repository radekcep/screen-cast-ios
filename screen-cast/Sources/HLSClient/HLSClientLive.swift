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

// swiftlint:disable all

extension HLSClient {
    public static var live: Self {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let streamDirectoryURL = temporaryDirectoryURL.appendingPathComponent("stream", isDirectory: true)

        try? FileManager.default.removeItem(at: streamDirectoryURL)

        let delegate = Delegate()
        let writer = AVAssetWriter(contentType: UTType(AVFileType.mp4.rawValue)!)

        var offset: CMTime?
        var videoInput: AVAssetWriterInput!

        let group = NIOTSEventLoopGroup()

        return .init(
            startServer: {
                writer.delegate = delegate
                writer.outputFileTypeProfile = .mpeg4AppleHLS
                writer.preferredOutputSegmentInterval = CMTime(seconds: 1, preferredTimescale: 1)
                writer.initialSegmentStartTime = CMTime.zero
                let videoOutputSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 360,
                    AVVideoHeightKey: 640
                ]

                videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
                videoInput.expectsMediaDataInRealTime = true
                writer.add(videoInput)

                Task(priority: .high) {
                    let channel = try? await NIOTSListenerBootstrap(group: group)
                        .childChannelInitializer { channel in
                            channel.pipeline.configureHTTPServerPipeline(withPipeliningAssistance: true, withErrorHandling: true)
                                .flatMap {
                                    channel.pipeline.addHandler(HTTP1ServerHandler())
                                }
                        }
                        .bind(host: "192.168.1.162", port: 8099)
                        .get()

                    try? await channel?.closeFuture.get()
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
                        CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)

                        info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, offset)
                        CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault,
                                                              sampleBuffer: sampleBuffer,
                                                              sampleTimingEntryCount: 1,
                                                              sampleTimingArray: &info,
                                                              sampleBufferOut: &copyBuffer)
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

final class HTTP1ServerHandler: ChannelInboundHandler {

    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        guard case .head(let headData) = part else {
            return
        }

        print("👀", headData.uri)

        if headData.uri == "/" {
            // index.Processing that returns html as a response
            handleIndexPageRequest(context: context, data: data)
        }
        if headData.uri.contains("index") {
            handleIndexRequest(context: context, data: data)
        }
        if headData.uri.contains("segment") {
            let segment = headData.uri.replacingOccurrences(of: "/", with: "")
            handleSegmentRequest(context: context, data: data, segment: segment)
        }
    }

    private func handleIndexPageRequest(context: ChannelHandlerContext, data: NIOAny) {
        do {
            let path = Bundle.module.path(forResource: "index", ofType: "html")!
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let buffer = context.channel.allocator.buffer(data: data)
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Length", value: "\(data.count)")
            responseHeaders.add(name: "Content-Type", value: "text/html; charset=utf-8")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        } catch {
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .notFound)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    private func handleSegmentRequest(context: ChannelHandlerContext, data: NIOAny, segment: String) {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let streamDirectoryURL = temporaryDirectoryURL.appendingPathComponent("stream", isDirectory: true)
        let segmentURL = streamDirectoryURL.appendingPathComponent(segment)

        do {
            let data = try Data(contentsOf: segmentURL)
            let buffer = context.channel.allocator.buffer(data: data)
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Length", value: "\(data.count)")
            responseHeaders.add(name: "Content-Type", value: "video/m4s")

            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        } catch {
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .notFound)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    private func handleIndexRequest(context: ChannelHandlerContext, data: NIOAny) {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let streamDirectoryURL = temporaryDirectoryURL.appendingPathComponent("stream", isDirectory: true)
        let indexURL = streamDirectoryURL.appendingPathComponent("index.m3u8")

        do {
            let data = try Data(contentsOf: indexURL)
            let buffer = context.channel.allocator.buffer(data: data)
            var responseHeaders = HTTPHeaders()
            responseHeaders.add(name: "Content-Length", value: "\(data.count)")
            responseHeaders.add(name: "Content-Type", value: "application/vnd.apple.mpegurl")
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: responseHeaders)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        } catch {
            let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .notFound)
            context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}

class Delegate: NSObject, AVAssetWriterDelegate {
    var indexNumber = 0

    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let streamDirectoryURL = temporaryDirectoryURL.appendingPathComponent("stream", isDirectory: true)

        if !FileManager.default.fileExists(atPath: streamDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: streamDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        let segmentExtension = segmentReport == nil ? "mp4" : "m4s"
        let segmentName = "segment\(indexNumber).\(segmentExtension)"

        let oldIndex = try? String(contentsOf: streamDirectoryURL.appendingPathComponent("index.m3u8"), encoding: .utf8)
        let index = indexFile(content: oldIndex, segmentName: segmentName, index: indexNumber, duration: segmentReport?.trackReports.first?.duration.seconds)

        try? segmentData.write(to: streamDirectoryURL.appendingPathComponent(segmentName))
        try? index.data(using: .utf8)?.write(to: streamDirectoryURL.appendingPathComponent("index.m3u8"))

        indexNumber += 1
    }
}

extension Delegate {
    func indexFile(content: String?, segmentName: String, index: Int, duration: Double?) -> String {
        var content = content ?? ""

        if content.isEmpty {
            content = "#EXTM3U\n"
                + "#EXT-X-TARGETDURATION:\(1)\n"
                + "#EXT-X-VERSION:7\n"
                + "#EXT-X-MEDIA-SEQUENCE:1\n"
                + "#EXT-X-MAP:URI=\"\(segmentName)\"\n"
//                + "#EXT-X-PLAYLIST-TYPE:VOD\n"
//                + "#EXT-X-INDEPENDENT-SEGMENTS\n"
        } else if let duration = duration {
            content = content
                + "#EXTINF:\(String(format: "%1.5f", duration)),\t\n"
                + "\(segmentName)\n"
        }

        return content
    }
}
