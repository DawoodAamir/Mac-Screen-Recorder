import AVFoundation
import ScreenCaptureKit

/// Receives all media and writer lifecycle work on one serial queue.
final class MovieWriter: NSObject, SCStreamOutput, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.dd.screenrecorder.writer")
    private var writer: AVAssetWriter?
    private var video: AVAssetWriterInput?
    private var audio: AVAssetWriterInput?
    private var started = false
    private var failure: Error?

    func prepare(url: URL, width: Int, height: Int, audioEnabled: Bool) throws {
        try queue.sync {
            let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
            let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width, AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: min(24_000_000, width * height * 5)]])
            video.expectsMediaDataInRealTime = true
            guard writer.canAdd(video) else { throw RecorderError.encoder }
            writer.add(video)
            if audioEnabled {
                let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48000, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 128000])
                input.expectsMediaDataInRealTime = true
                guard writer.canAdd(input) else { throw RecorderError.encoder }
                writer.add(input); self.audio = input
            }
            self.writer = writer; self.video = video; self.started = false; self.failure = nil
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard sampleBuffer.isValid, let writer, writer.status != .failed else { return }
        if type == .screen {
            guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let raw = attachments.first?[.status] as? Int, SCFrameStatus(rawValue: raw) == .complete else { return }
            if !started {
                guard writer.startWriting() else { failure = writer.error ?? RecorderError.encoder; return }
                writer.startSession(atSourceTime: sampleBuffer.presentationTimeStamp); started = true
            }
            if video?.isReadyForMoreMediaData == true, video?.append(sampleBuffer) == false { failure = writer.error }
        } else if #available(macOS 13.0, *), type == .audio, started, audio?.isReadyForMoreMediaData == true {
            if audio?.append(sampleBuffer) == false { failure = writer.error }
        }
    }

    func finish() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                guard let writer = self.writer else { continuation.resume(throwing: RecorderError.noFrames); return }
                if let error = self.failure ?? writer.error { writer.cancelWriting(); continuation.resume(throwing: error); return }
                guard self.started else { writer.cancelWriting(); continuation.resume(throwing: RecorderError.noFrames); return }
                self.video?.markAsFinished(); self.audio?.markAsFinished()
                writer.finishWriting {
                    if writer.status == .completed { continuation.resume() }
                    else { continuation.resume(throwing: writer.error ?? RecorderError.encoder) }
                }
            }
        }
    }
    func cancel() { queue.sync { writer?.cancelWriting() } }
}

enum RecorderError: LocalizedError {
    case noFrames, encoder, noSource
    var errorDescription: String? {
        switch self {
        case .noFrames: return "No video frames were received. Keep the selected window visible and record for at least a second."
        case .encoder: return "The video encoder could not finish this recording."
        case .noSource: return "The selected source is no longer available. Refresh the source list."
        }
    }
}
