import Foundation

public enum FoldCurve {
    public static let blurExponent = 1.35
    public static let darkenExponent = 1.35
    public static let darkenStart = 0.2
    public static let darkenStrength = 2.0

    public static func smoothstep(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    public static func motion(angle: Double, startAngle: Double, endAngle: Double) -> Double {
        guard startAngle > endAngle else { return angle < startAngle ? 1 : 0 }
        return smoothstep((startAngle - angle) / (startAngle - endAngle))
    }

    public static func blurWeight(edge: Double) -> Double {
        pow(min(max(edge, 0), 1), blurExponent)
    }

    public static func blurRadius(edge: Double, motion: Double, maxRadius: Double) -> Double {
        maxRadius * motion * blurWeight(edge: edge)
    }

    public static func darkenAlpha(edge: Double, motion: Double) -> Double {
        let gradient = min(max((edge - darkenStart) / (1 - darkenStart), 0), 1)
        return min(1, darkenStrength * motion * pow(gradient, darkenExponent))
    }
}
