import Foundation

public struct AngleSmoother {
    public var timeConstant: Double
    public var settleTolerance: Double
    public private(set) var value: Double?
    private var target: Double?

    public init(timeConstant: Double = 0.12, settleTolerance: Double = 0.05) {
        self.timeConstant = timeConstant
        self.settleTolerance = settleTolerance
    }

    public var isSettled: Bool {
        guard let value, let target else { return true }
        return abs(target - value) <= settleTolerance
    }

    @discardableResult
    public mutating func step(toward newTarget: Double, dt: Double) -> Double {
        target = newTarget
        guard let current = value else {
            value = newTarget
            return newTarget
        }
        let blend = 1 - exp(-max(dt, 0) / timeConstant)
        var next = current + (newTarget - current) * blend
        if abs(newTarget - next) <= settleTolerance { next = newTarget }
        value = next
        return next
    }

    public mutating func reset() {
        value = nil
        target = nil
    }
}
