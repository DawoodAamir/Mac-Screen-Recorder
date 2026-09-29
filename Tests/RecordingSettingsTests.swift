import XCTest

@testable import RecorderCore

final class RecordingSettingsTests: XCTestCase {
    func testEncoderDimensionsAreEvenAndWithin4K() {
        let size = RecordingSettings.dimensions(width: 6017, height: 3385)
        XCTAssertLessThanOrEqual(size.width, 3840)
        XCTAssertEqual(size.width % 2, 0)
        XCTAssertEqual(size.height % 2, 0)
    }
    func testInvalidFrameRateUsesSafeDefault() {
        XCTAssertEqual(RecordingSettings(framesPerSecond: -1).framesPerSecond, 30)
    }
    func testEmptyDimensionsNeverReachEncoder() {
        let size = RecordingSettings.dimensions(width: 0, height: 0)
        XCTAssertEqual(size.width, 2)
        XCTAssertEqual(size.height, 2)
    }
}
