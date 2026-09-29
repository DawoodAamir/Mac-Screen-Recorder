<img src="Resources/Assets.xcassets/AppIcon.appiconset/mac-512-2.png" width="80" alt="Mac Screen Recorder icon">

# Mac Screen Recorder

A native Mac recorder for a single window or display, with local H.264 files and optional system audio.

**macOS 12.3+ · system audio on macOS 13+ · Swift · MIT License**

## What it does

- Discover windows and displays through ScreenCaptureKit.
- Record at 24, 30, or 60 fps, with even encoder dimensions capped at 4K.
- Include system audio on macOS 13 and later.
- Keep recordings in a local library, play them, and export MOV files.

## Run

Open `Mac Screen Recorder.xcodeproj` in Xcode 16 or later. The shared scheme has the same name. No third-party Swift packages are required. Builds were checked with Xcode 27; minimum OS declarations are not a claim that every older OS was runtime-tested.

Choose My Mac and run the shared scheme. Click Find sources and grant Screen Recording access when macOS requests it. Reopen the app if the system requires it.

Select a source, start recording, then stop before closing the app. Signing is ad hoc for local development; distribution requires your own Developer ID signing and notarization.

Bundle identifier: `com.dd.screenrecorder`.

## Try it

Record a small window for a few seconds, stop, then use Play. Export the recording to a folder of your choice. ⌘⇧R starts or stops capture.

## Implementation

`RecorderModel` owns source discovery and the capture lifecycle. `MovieWriter` serializes AVAssetWriter operations and sample delivery on one queue. `RecordingSettings` keeps frame-rate and encoder-size rules testable without screen permission.

## Verification

Run `swift test` for encoder dimensions and frame-rate validation. Verify permission denial, a short window recording, playback, system audio, and export on a Mac with Screen Recording permission.

## Scope and limitations

There is no microphone input, video editing, pause/resume, or cloud upload. Quitting waits for an active recording to finish. A forced process termination can still leave an incomplete file. Real capture and system audio require OS permission and must be checked on the target Mac. A successful build alone does not verify capture permissions.

## Data and privacy

See [PRIVACY.md](PRIVACY.md) for storage and network behavior. Sample data is fictional.

## License

[MIT](LICENSE). Original source and app artwork are included under the same license.
