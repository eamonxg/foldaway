import XCTest
@testable import FoldawayCore

final class FoldSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "FoldawayCoreTests.\(UUID().uuidString)"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testDefaults() {
        let settings = FoldSettings()
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.startAngle, 85)
        XCTAssertEqual(settings.endAngle, 15)
        XCTAssertEqual(settings.maxBlurRadius, 48)
    }

    func testNormalizedClampsIntoRangesAndKeepsSpan() {
        var settings = FoldSettings()
        settings.startAngle = 200
        settings.endAngle = -5
        settings.maxBlurRadius = 500
        let normalized = settings.normalized()
        XCTAssertEqual(normalized.startAngle, 125)
        XCTAssertEqual(normalized.endAngle, 0)
        XCTAssertEqual(normalized.maxBlurRadius, 80)

        settings = FoldSettings()
        settings.startAngle = 60
        settings.endAngle = 45
        XCTAssertEqual(settings.normalized().endAngle, 45)
        settings.endAngle = 50
        XCTAssertEqual(settings.normalized().endAngle, 45)
        settings.startAngle = 70
        settings.endAngle = 45
        XCTAssertEqual(settings.normalized().endAngle, 45)
        settings.startAngle = 58
        XCTAssertEqual(settings.normalized().startAngle, 60)
        XCTAssertEqual(settings.normalized().endAngle, 45)
    }

    func testRoundTripsThroughUserDefaults() {
        var settings = FoldSettings()
        settings.isEnabled = false
        settings.startAngle = 100
        settings.endAngle = 20
        settings.maxBlurRadius = 30
        settings.save(to: defaults)
        XCTAssertEqual(FoldSettings.load(from: defaults), settings)
    }

    func testEmptyDefaultsLoadAsDefaults() {
        XCTAssertEqual(FoldSettings.load(from: defaults), FoldSettings())
    }
}
