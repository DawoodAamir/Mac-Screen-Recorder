import SwiftUI

@main
struct ScreenRecorderApp: App {
    @StateObject private var recorder = RecorderModel()
    @NSApplicationDelegateAdaptor(RecorderAppDelegate.self) private var delegate
    var body: some Scene {
        WindowGroup {
            RecorderView().environmentObject(recorder).tint(Color("AccentColor"))
                .frame(minWidth: 780, minHeight: 560)
                .onAppear { delegate.recorder = recorder }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Recording") {
                Button(recorder.recording ? "Stop Recording" : "Start Recording") {
                    Task {
                        if recorder.recording {
                            await recorder.stop()
                        } else {
                            await recorder.start()
                        }
                    }
                }.keyboardShortcut("r", modifiers: [.command, .shift]).disabled(
                    recorder.busy || (!recorder.recording && recorder.selectedID == nil))
            }
        }
    }
}

struct RecorderView: View {
    @EnvironmentObject private var recorder: RecorderModel
    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Capture source").font(.headline)
                Text("Choose a display or a single window.").font(.subheadline).foregroundColor(
                    .secondary)
                List(recorder.sources, selection: $recorder.selectedID) { source in
                    VStack(alignment: .leading, spacing: 5) {
                        Label(
                            source.name,
                            systemImage: source.display == nil ? "macwindow" : "display"
                        ).lineLimit(2)
                        Text(source.detail).font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical, 4).tag(source.id)
                }.disabled(recorder.recording || recorder.busy)
                Button("Find sources") { Task { await recorder.refreshSources() } }.disabled(
                    recorder.recording || recorder.busy)
                Text("macOS asks for Screen Recording access when you first find sources.").font(
                    .caption
                ).foregroundColor(.secondary)
            }.padding(20).frame(minWidth: 230, idealWidth: 270, maxWidth: 340)
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keep the moment.").font(.system(.largeTitle, design: .serif)).fontWeight(
                        .semibold)
                    Text("Window and display recording, saved on your Mac.").foregroundColor(
                        .secondary)
                }
                GroupBox {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: recorder.recording ? "record.circle.fill" : "display")
                                .font(.system(size: 32)).foregroundColor(
                                    recorder.recording ? .red : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recorder.recording ? "Recording" : "Ready when you are").font(
                                    .headline)
                                if let start = recorder.startedAt {
                                    Text(start, style: .timer).monospacedDigit()
                                } else {
                                    Text("Select a source, then start.").foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        Picker("Frame rate", selection: $recorder.settings.framesPerSecond) {
                            Text("24 fps").tag(24)
                            Text("30 fps").tag(30)
                            Text("60 fps").tag(60)
                        }.disabled(recorder.recording || recorder.busy)
                        if #available(macOS 13.0, *) {
                            Toggle("Include system audio", isOn: $recorder.settings.includesAudio)
                                .disabled(recorder.recording || recorder.busy)
                        } else {
                            Text("System audio recording requires macOS 13.").font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Button {
                                Task {
                                    if recorder.recording {
                                        await recorder.stop()
                                    } else {
                                        await recorder.start()
                                    }
                                }
                            } label: {
                                Label(
                                    recorder.recording ? "Stop recording" : "Start recording",
                                    systemImage: recorder.recording ? "stop.fill" : "record.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(
                                recorder.busy || (!recorder.recording && recorder.selectedID == nil)
                            )
                            if recorder.busy { ProgressView().controlSize(.small) }
                        }
                    }.padding(14)
                }
                Text("Recent recordings").font(.headline)
                if recorder.recordings.isEmpty {
                    Text(
                        "Your recordings will appear here. Files stay in the app’s local library until you export them."
                    ).foregroundColor(.secondary)
                }
                List(recorder.recordings) { recording in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recording.created.formatted(date: .abbreviated, time: .shortened))
                                .font(.headline)
                            Text(
                                ByteCountFormatter.string(
                                    fromByteCount: Int64(recording.size), countStyle: .file)
                            ).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Play") { NSWorkspace.shared.open(recording.url) }
                        Button("Export…") { recorder.export(recording) }
                    }.padding(.vertical, 4)
                }
                Text("H.264 video · MOV files · Up to 4K · No uploads").font(.caption)
                    .foregroundColor(.secondary)
            }.padding(28).frame(minWidth: 440)
        }.alert(
            "Screen recorder",
            isPresented: Binding(
                get: { recorder.error != nil }, set: { if !$0 { recorder.error = nil } })
        ) {
            Button("OK") { recorder.error = nil }
        } message: {
            Text(recorder.error ?? "")
        }
    }
}

@MainActor
final class RecorderAppDelegate: NSObject, NSApplicationDelegate {
    weak var recorder: RecorderModel?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let recorder, recorder.recording else { return .terminateNow }
        Task {
            // If a stop is already finalizing, wait for it rather than interrupting the writer.
            while recorder.busy { try? await Task.sleep(nanoseconds: 100_000_000) }
            if recorder.recording { await recorder.stop() }
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
