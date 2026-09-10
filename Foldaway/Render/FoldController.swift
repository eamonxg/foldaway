import AppKit
import FoldawayCore

final class FoldController: NSObject {
    private static let idlePollInterval = 1.0 / 20.0
    private static let motionThreshold = 0.002

    var settings: FoldSettings {
        didSet {
            settings.save(to: .standard)
            wakeIfNeeded()
        }
    }
    private(set) var lidAngle: Double? {
        didSet {
            guard lidAngle != oldValue else { return }
            onLidAngleChange?(lidAngle)
            diagnostics?("angle \(oldValue.map { "\($0)" } ?? "nil") -> \(lidAngle.map { "\($0)" } ?? "nil") raw=\(sensor.lastReport.map { String(format: "%02x", $0) }.joined(separator: " ")) result=\(sensor.lastResult)")
        }
    }
    var diagnostics: ((String) -> Void)?
    var onLidAngleChange: ((Double?) -> Void)?
    var forcedMotion: Double? {
        didSet { wakeIfNeeded() }
    }
    var isSensorAvailable: Bool { sensor.isAvailable }
    var sensorFailures: Int { sensor.consecutiveFailures }
    let isBlurSupported = FoldLayer.isBlurSupported

    private let sensor: LidAngleSensor
    private var pollTimer: Timer?
    private var displayLink: CADisplayLink?
    private var window: FoldOverlayWindow?
    private var layer: FoldLayer?
    private var smoother = AngleSmoother()
    private var preview: (startedAt: CFTimeInterval, timeline: FoldPreview)?
    private var lastFrameTime: CFTimeInterval?
    private var screenObserver: NSObjectProtocol?

    init(sensor: LidAngleSensor, settings: FoldSettings) {
        self.sensor = sensor
        self.settings = settings
    }

    func start() {
        rebuildWindow()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.rebuildWindow()
        }
        let timer = Timer(timeInterval: Self.idlePollInterval, repeats: true) { [weak self] _ in self?.poll() }
        timer.tolerance = Self.idlePollInterval / 2
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        poll()
    }

    func startPreview() {
        preview = (CACurrentMediaTime(), FoldPreview(startAngle: settings.startAngle, endAngle: settings.endAngle))
        resumeDisplayLink()
    }

    private func poll() {
        lidAngle = sensor.read()
        wakeIfNeeded()
    }

    private func wakeIfNeeded() {
        guard let displayLink, displayLink.isPaused else { return }
        if forcedMotion != nil || preview != nil || liveMotion() > 0 { resumeDisplayLink() }
    }

    private func liveMotion() -> Double {
        guard settings.isEnabled, let lidAngle else { return 0 }
        return motion(forAngle: lidAngle)
    }

    private func motion(forAngle angle: Double) -> Double {
        let motion = FoldCurve.motion(angle: angle, startAngle: settings.startAngle, endAngle: settings.endAngle)
        return motion < Self.motionThreshold ? 0 : motion
    }

    private func previewAngle(at time: CFTimeInterval) -> Double? {
        guard let preview else { return nil }
        if let angle = preview.timeline.angle(at: time - preview.startedAt) { return angle }
        self.preview = nil
        return nil
    }

    @objc private func frame(_ link: CADisplayLink) {
        let now = link.targetTimestamp
        let dt = lastFrameTime.map { now - $0 } ?? 0
        lastFrameTime = now
        lidAngle = sensor.read()
        let motion: Double
        if let forcedMotion {
            motion = forcedMotion
        } else if let angle = previewAngle(at: now) ?? (settings.isEnabled ? lidAngle : nil) {
            motion = self.motion(forAngle: smoother.step(toward: angle, dt: dt))
        } else {
            smoother.reset()
            motion = 0
        }
        render(motion: motion)
        if motion == 0, smoother.isSettled, preview == nil, forcedMotion == nil { pauseDisplayLink() }
    }

    private func render(motion: Double) {
        guard let window, let layer else { return }
        layer.apply(motion: motion, maxRadius: settings.maxBlurRadius)
        if motion > 0 {
            if !window.isVisible {
                window.orderFrontRegardless()
                diagnostics?("overlay shown, motion \(motion)")
            }
        } else if window.isVisible {
            window.orderOut(nil)
            diagnostics?("overlay hidden")
        }
    }

    private func rebuildWindow() {
        displayLink?.invalidate()
        displayLink = nil
        window?.orderOut(nil)
        window = nil
        layer = nil
        guard let screen = Self.builtInScreen() else { return }
        let foldLayer = FoldLayer()
        foldLayer.contentsScale = screen.backingScaleFactor
        let host = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        host.layer = foldLayer
        host.wantsLayer = true
        let window = FoldOverlayWindow(screen: screen)
        window.contentView = host
        foldLayer.setNeedsLayout()
        self.window = window
        layer = foldLayer
        let link = screen.displayLink(target: self, selector: #selector(frame(_:)))
        link.isPaused = true
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastFrameTime = nil
        wakeIfNeeded()
    }

    private static func builtInScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(number.uint32Value) != 0
        }
    }

    private func resumeDisplayLink() {
        guard let displayLink, displayLink.isPaused else { return }
        smoother.reset()
        lastFrameTime = nil
        displayLink.isPaused = false
        diagnostics?("display link resumed")
    }

    private func pauseDisplayLink() {
        displayLink?.isPaused = true
        lastFrameTime = nil
        diagnostics?("display link paused")
    }
}
