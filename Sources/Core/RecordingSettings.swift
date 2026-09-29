import Foundation

public struct RecordingSettings: Equatable {
    public var framesPerSecond: Int
    public var includesAudio: Bool
    public init(framesPerSecond: Int = 30, includesAudio: Bool = false) {
        self.framesPerSecond = [24, 30, 60].contains(framesPerSecond) ? framesPerSecond : 30
        self.includesAudio = includesAudio
    }
    public static func dimensions(width: Double, height: Double, scale: Double = 2) -> (width: Int, height: Int) {
        let ratio = min(scale, 3840 / max(1, max(width, height)))
        return (max(2, Int(width * ratio) / 2 * 2), max(2, Int(height * ratio) / 2 * 2))
    }
}
