import AppKit
import ScreenCaptureKit
import Combine

struct CaptureSource: Identifiable {
    let id: String
    let name: String
    let detail: String
    let display: SCDisplay?
    let window: SCWindow?
}
struct Recording: Identifiable {
    let url: URL
    let created: Date
    let size: Int
    var id: URL { url }
}

@MainActor
final class RecorderModel: NSObject, ObservableObject, SCStreamDelegate {
    @Published var sources: [CaptureSource] = []
    @Published var selectedID: String?
    @Published var settings = RecordingSettings()
    @Published private(set) var recording = false
    @Published private(set) var busy = false
    @Published private(set) var startedAt: Date?
    @Published private(set) var recordings: [Recording] = []
    @Published var error: String?
    private var stream: SCStream?
    private var writer: MovieWriter?
    private var destination: URL?
    private var applications: [SCRunningApplication] = []
    private let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("MacScreenRecorder/Recordings", isDirectory: true)

    override init() { super.init(); refreshRecordings() }
    func refreshSources() async {
        guard !recording else { return }
        busy = true; defer { busy = false }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            applications = content.applications
            sources = content.displays.enumerated().map { index, display in
                CaptureSource(id: "display-\(display.displayID)", name: "Display \(index + 1)", detail: "\(display.width) × \(display.height)", display: display, window: nil)
            } + content.windows.filter { $0.owningApplication?.processID != ProcessInfo.processInfo.processIdentifier && !($0.title ?? "").isEmpty && $0.frame.width > 100 }.map {
                CaptureSource(id: "window-\($0.windowID)", name: $0.title ?? "Untitled window", detail: $0.owningApplication?.applicationName ?? "Window", display: nil, window: $0)
            }
            if !sources.contains(where: { $0.id == selectedID }) { selectedID = sources.first?.id }
        } catch { self.error = "Screen access is unavailable. Allow Screen Recording in System Settings, then reopen the app if requested. \(error.localizedDescription)" }
    }
    func start() async {
        guard !recording, !busy else { return }
        busy = true; defer { busy = false }
        do {
            guard let source = sources.first(where: { $0.id == selectedID }) else { throw RecorderError.noSource }
            let filter: SCContentFilter
            let dimensions: (width: Int, height: Int)
            if let display = source.display {
                filter = SCContentFilter(display: display, excludingApplications: applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }, exceptingWindows: [])
                dimensions = RecordingSettings.dimensions(width: Double(display.width), height: Double(display.height), scale: 1)
            } else if let window = source.window {
                filter = SCContentFilter(desktopIndependentWindow: window)
                dimensions = RecordingSettings.dimensions(width: window.frame.width, height: window.frame.height)
            } else { throw RecorderError.noSource }
            let config = SCStreamConfiguration()
            config.width = dimensions.width; config.height = dimensions.height
            config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(settings.framesPerSecond))
            config.queueDepth = 5; config.showsCursor = true
            var audioEnabled = false
            if #available(macOS 13.0, *) {
                config.capturesAudio = settings.includesAudio
                config.excludesCurrentProcessAudio = true
                config.sampleRate = 48000; config.channelCount = 2
                audioEnabled = settings.includesAudio
            }
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("Recording-\(UUID().uuidString).mov")
            destination = url
            let writer = MovieWriter()
            try writer.prepare(url: url, width: dimensions.width, height: dimensions.height, audioEnabled: audioEnabled)
            self.writer = writer
            let stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream.addStreamOutput(writer, type: .screen, sampleHandlerQueue: writer.queue)
            if #available(macOS 13.0, *), audioEnabled { try stream.addStreamOutput(writer, type: .audio, sampleHandlerQueue: writer.queue) }
            self.stream = stream
            try await stream.startCapture()
            recording = true; startedAt = Date()
        } catch {
            writer?.cancel(); cleanupIncomplete(); self.error = error.localizedDescription
            stream = nil; writer = nil
        }
    }
    func stop() async {
        guard recording, !busy else { return }
        busy = true; defer { busy = false; recording = false; startedAt = nil; stream = nil; writer = nil }
        do {
            try await stream?.stopCapture()
            try await writer?.finish()
            destination = nil; refreshRecordings()
        } catch { self.error = error.localizedDescription; cleanupIncomplete() }
    }
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            guard self.recording else { return }
            self.error = "Capture was interrupted. \(error.localizedDescription)"
            await self.stop()
        }
    }
    private func cleanupIncomplete() {
        if let destination { try? FileManager.default.removeItem(at: destination) }
        destination = nil
    }
    private func refreshRecordings() {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            recordings = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]).filter { $0.pathExtension == "mov" }.map {
                let values = try $0.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                return Recording(url: $0, created: values.creationDate ?? .distantPast, size: values.fileSize ?? 0)
            }.sorted { $0.created > $1.created }
        } catch { self.error = error.localizedDescription }
    }
    func export(_ recording: Recording) {
        let panel = NSSavePanel(); panel.nameFieldStringValue = "Screen recording.mov"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: recording.url, options: .mappedIfSafe)
            try data.write(to: url, options: .atomic)
        } catch { self.error = error.localizedDescription }
    }
}
