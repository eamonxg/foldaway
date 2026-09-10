import XCTest
@testable import FoldawayCore

final class FoldCurveTests: XCTestCase {
    func testSmoothstepClampsAndEases() {
        XCTAssertEqual(FoldCurve.smoothstep(-1), 0)
        XCTAssertEqual(FoldCurve.smoothstep(0), 0)
        XCTAssertEqual(FoldCurve.smoothstep(0.25), 0.15625, accuracy: 1e-12)
        XCTAssertEqual(FoldCurve.smoothstep(0.5), 0.5, accuracy: 1e-12)
        XCTAssertEqual(FoldCurve.smoothstep(1), 1)
        XCTAssertEqual(FoldCurve.smoothstep(2), 1)
    }

    func testMotionFollowsLidAngle() {
        XCTAssertEqual(FoldCurve.motion(angle: 120, startAngle: 85, endAngle: 15), 0)
        XCTAssertEqual(FoldCurve.motion(angle: 85, startAngle: 85, endAngle: 15), 0)
        XCTAssertEqual(FoldCurve.motion(angle: 50, startAngle: 85, endAngle: 15), 0.5, accuracy: 1e-12)
        XCTAssertEqual(FoldCurve.motion(angle: 15, startAngle: 85, endAngle: 15), 1)
        XCTAssertEqual(FoldCurve.motion(angle: 0, startAngle: 85, endAngle: 15), 1)
    }

    func testMotionWithDegenerateRangeIsAStep() {
        XCTAssertEqual(FoldCurve.motion(angle: 50, startAngle: 40, endAngle: 40), 0)
        XCTAssertEqual(FoldCurve.motion(angle: 30, startAngle: 40, endAngle: 40), 1)
    }

    func testBlurWeightIsZeroAtHingeAndFullAtFarEdge() {
        XCTAssertEqual(FoldCurve.blurWeight(edge: 0), 0)
        XCTAssertEqual(FoldCurve.blurWeight(edge: 0.5), pow(0.5, 1.35), accuracy: 1e-12)
        XCTAssertEqual(FoldCurve.blurWeight(edge: 1), 1)
        XCTAssertEqual(FoldCurve.blurWeight(edge: 1.5), 1)
    }

    func testBlurRadiusScalesWithMotionAndMaxRadius() {
        XCTAssertEqual(FoldCurve.blurRadius(edge: 1, motion: 1, maxRadius: 48), 48)
        XCTAssertEqual(FoldCurve.blurRadius(edge: 1, motion: 0.5, maxRadius: 48), 24)
        XCTAssertEqual(FoldCurve.blurRadius(edge: 0, motion: 1, maxRadius: 48), 0)
    }

    func testDarkenAlphaLeavesHingeSideLit() {
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 0, motion: 1), 0)
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 0.2, motion: 1), 0)
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 1, motion: 0), 0)
    }

    func testDarkenAlphaIsTwiceStrengthCappedAtBlack() {
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 1, motion: 0.25), 0.5, accuracy: 1e-12)
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 1, motion: 0.5), 1)
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 1, motion: 1), 1)
        XCTAssertEqual(FoldCurve.darkenAlpha(edge: 0.6, motion: 1), 2 * pow(0.5, 1.35), accuracy: 1e-12)
    }
}
