import Foundation

public struct FoldPreview {
    public static let closeDuration = 1.4
    public static let holdDuration = 0.6
    public static let openDuration = 1.4
    public static var totalDuration: Double { closeDuration + holdDuration + openDuration }

    public let startAngle: Double
    public let endAngle: Double

    public init(startAngle: Double, endAngle: Double) {
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    public func angle(at time: Double) -> Double? {
        guard time < Self.totalDuration else { return nil }
        let progress: Double
        if time < Self.closeDuration {
            progress = FoldCurve.smoothstep(time / Self.closeDuration)
        } else if time < Self.closeDuration + Self.holdDuration {
            progress = 1
        } else {
            progress = 1 - FoldCurve.smoothstep((time - Self.closeDuration - Self.holdDuration) / Self.openDuration)
        }
        return startAngle + (endAngle - startAngle) * progress
    }
}
