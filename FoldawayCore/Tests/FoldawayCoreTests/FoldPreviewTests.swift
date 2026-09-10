import XCTest
@testable import FoldawayCore

final class FoldPreviewTests: XCTestCase {
    private let preview = FoldPreview(startAngle: 85, endAngle: 15)

    func testStartsOpenAndClosesWithSmoothstep() {
        XCTAssertEqual(preview.angle(at: 0), 85)
        XCTAssertEqual(preview.angle(at: 0.7)!, 50, accuracy: 1e-9)
        XCTAssertEqual(preview.angle(at: 1.4)!, 15, accuracy: 1e-9)
    }

    func testHoldsClosedThenReopens() {
        XCTAssertEqual(preview.angle(at: 1.7)!, 15, accuracy: 1e-9)
        XCTAssertEqual(preview.angle(at: 2.7)!, 50, accuracy: 1e-9)
        XCTAssertEqual(preview.angle(at: 3.39)!, 85, accuracy: 0.05)
    }

    func testFinishesAfterTotalDuration() {
        XCTAssertEqual(FoldPreview.totalDuration, 3.4, accuracy: 1e-12)
        XCTAssertNil(preview.angle(at: FoldPreview.totalDuration))
        XCTAssertNil(preview.angle(at: 10))
    }
}
