import Foundation

public struct FoldSettings: Equatable {
    public static let startAngleRange: ClosedRange<Double> = 60...125
    public static let endAngleRange: ClosedRange<Double> = 0...45
    public static let maxBlurRadiusRange: ClosedRange<Double> = 8...80
    public static let minimumSpan = 15.0

    public var isEnabled = true
    public var startAngle = 85.0
    public var endAngle = 15.0
    public var maxBlurRadius = 48.0

    public init() {}

    public func normalized() -> FoldSettings {
        var settings = self
        settings.startAngle = Self.startAngleRange.clamping(settings.startAngle)
        settings.endAngle = Self.endAngleRange.clamping(settings.endAngle)
        settings.maxBlurRadius = Self.maxBlurRadiusRange.clamping(settings.maxBlurRadius)
        if settings.startAngle - settings.endAngle < Self.minimumSpan {
            settings.endAngle = Self.endAngleRange.clamping(settings.startAngle - Self.minimumSpan)
        }
        return settings
    }

    private enum Key {
        static let isEnabled = "isEnabled"
        static let startAngle = "startAngle"
        static let endAngle = "endAngle"
        static let maxBlurRadius = "maxBlurRadius"
    }

    public static func load(from defaults: UserDefaults) -> FoldSettings {
        var settings = FoldSettings()
        if defaults.object(forKey: Key.isEnabled) != nil { settings.isEnabled = defaults.bool(forKey: Key.isEnabled) }
        if defaults.object(forKey: Key.startAngle) != nil { settings.startAngle = defaults.double(forKey: Key.startAngle) }
        if defaults.object(forKey: Key.endAngle) != nil { settings.endAngle = defaults.double(forKey: Key.endAngle) }
        if defaults.object(forKey: Key.maxBlurRadius) != nil { settings.maxBlurRadius = defaults.double(forKey: Key.maxBlurRadius) }
        return settings.normalized()
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(isEnabled, forKey: Key.isEnabled)
        defaults.set(startAngle, forKey: Key.startAngle)
        defaults.set(endAngle, forKey: Key.endAngle)
        defaults.set(maxBlurRadius, forKey: Key.maxBlurRadius)
    }
}

private extension ClosedRange where Bound == Double {
    func clamping(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
