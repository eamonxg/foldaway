import XCTest
@testable import FoldawayCore

final class AngleSmootherTests: XCTestCase {
    func testFirstStepSnapsToTarget() {
        var smoother = AngleSmoother()
        XCTAssertEqual(smoother.step(toward: 98, dt: 1 / 60), 98)
        XCTAssertTrue(smoother.isSettled)
    }

    func testApproachesTargetWithoutOvershoot() {
        var smoother = AngleSmoother(timeConstant: 0.12)
        smoother.step(toward: 100, dt: 1 / 120)
        let first = smoother.step(toward: 90, dt: 1 / 120)
        let second = smoother.step(toward: 90, dt: 1 / 120)
        XCTAssertLessThan(first, 100)
        XCTAssertGreaterThan(first, 90)
        XCTAssertLessThan(second, first)
        XCTAssertGreaterThan(second, 90)
        XCTAssertFalse(smoother.isSettled)
    }

    func testOneTimeConstantLeavesOneOverEOfTheGap() {
        var smoother = AngleSmoother(timeConstant: 0.12)
        smoother.step(toward: 100, dt: 0)
        XCTAssertEqual(smoother.step(toward: 0, dt: 0.12), 100 * exp(-1), accuracy: 1e-9)
    }

    func testSettlesAndSnapsWithinTolerance() {
        var smoother = AngleSmoother(timeConstant: 0.12)
        smoother.step(toward: 100, dt: 0)
        for _ in 0..<240 { smoother.step(toward: 60, dt: 1 / 120) }
        XCTAssertEqual(smoother.value, 60)
        XCTAssertTrue(smoother.isSettled)
    }

    func testZeroDtKeepsValue() {
        var smoother = AngleSmoother()
        smoother.step(toward: 100, dt: 0)
        XCTAssertEqual(smoother.step(toward: 50, dt: 0), 100)
        XCTAssertFalse(smoother.isSettled)
    }

    func testResetSnapsAgain() {
        var smoother = AngleSmoother()
        smoother.step(toward: 100, dt: 0)
        smoother.reset()
        XCTAssertEqual(smoother.step(toward: 20, dt: 1 / 60), 20)
    }
}
