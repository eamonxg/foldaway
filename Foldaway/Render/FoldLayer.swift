import AppKit
import FoldawayCore

final class FoldLayer: CALayer {
    private static let filterType = "variableBlur"
    private static let radiusKeyPath = "filters.variableBlur.inputRadius"
    private static let maskKeyPath = "filters.variableBlur.inputMaskImage"
    private static let veilStopCount = 33

    static var isBlurSupported: Bool { makeBackdrop() != nil }

    private let backdrop: CALayer?
    private let veil = CAGradientLayer()
    private var maskPixelHeight = 0
    private(set) var motion = 0.0
    private(set) var maxRadius = 0.0

    override init() {
        backdrop = Self.makeBackdrop()
        super.init()
        if let backdrop { addSublayer(backdrop) }
        veil.startPoint = CGPoint(x: 0.5, y: 0)
        veil.endPoint = CGPoint(x: 0.5, y: 1)
        veil.locations = (0..<Self.veilStopCount).map { NSNumber(value: Double($0) / Double(Self.veilStopCount - 1)) }
        veil.colors = Self.veilColors(motion: 0)
        addSublayer(veil)
    }

    override init(layer: Any) {
        backdrop = nil
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        backdrop?.frame = bounds
        veil.frame = bounds
        let pixelHeight = Int((bounds.height * contentsScale).rounded())
        guard pixelHeight != maskPixelHeight, let mask = FoldMask.image(pixelHeight: pixelHeight) else { return }
        maskPixelHeight = pixelHeight
        backdrop?.setValue(mask, forKeyPath: Self.maskKeyPath)
    }

    func apply(motion: Double, maxRadius: Double) {
        guard motion != self.motion || maxRadius != self.maxRadius else { return }
        self.motion = motion
        self.maxRadius = maxRadius
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop?.setValue(maxRadius * motion, forKeyPath: Self.radiusKeyPath)
        veil.colors = Self.veilColors(motion: motion)
        CATransaction.commit()
    }

    private static func veilColors(motion: Double) -> [CGColor] {
        (0..<veilStopCount).map { index in
            CGColor(gray: 0, alpha: FoldCurve.darkenAlpha(edge: Double(index) / Double(veilStopCount - 1), motion: motion))
        }
    }

    private static func makeBackdrop() -> CALayer? {
        guard let layerClass = NSClassFromString("CABackdropLayer") as? CALayer.Type,
              let filterClass = NSClassFromString("CAFilter") as? NSObject.Type else { return nil }
        let selector = NSSelectorFromString("filterWithType:")
        guard filterClass.responds(to: selector),
              let filter = filterClass.perform(selector, with: filterType)?.takeUnretainedValue() as? NSObject else { return nil }
        filter.setValue(filterType, forKey: "name")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        filter.setValue(0, forKey: "inputRadius")
        let layer = layerClass.init()
        layer.filters = [filter]
        return layer
    }
}
