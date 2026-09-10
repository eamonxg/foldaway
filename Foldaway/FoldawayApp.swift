import AppKit
import FoldawayCore

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var shared: AppDelegate?

    private var controller: FoldController?
    private var statusMenu: StatusMenuController?
    private var angleLogger: Timer?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        shared = delegate
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = FoldController(sensor: LidAngleSensor(), settings: FoldSettings.load(from: .standard))
        self.controller = controller
        statusMenu = StatusMenuController(controller: controller)
        controller.start()
        applyLaunchArguments(to: controller)
    }

    private func applyLaunchArguments(to controller: FoldController) {
        let arguments = CommandLine.arguments
        if let index = arguments.firstIndex(of: "--motion"), index + 1 < arguments.count, let motion = Double(arguments[index + 1]) {
            controller.forcedMotion = min(max(motion, 0), 1)
        }
        if arguments.contains("--preview") {
            controller.startPreview()
        }
        if arguments.contains("--log-angle") {
            let clock = DateFormatter()
            clock.dateFormat = "HH:mm:ss.SSS"
            let log: (String) -> Void = { line in
                print(clock.string(from: Date()), line)
                fflush(stdout)
            }
            controller.diagnostics = log
            log("sensor available: \(controller.isSensorAvailable), blur supported: \(controller.isBlurSupported)")
            angleLogger = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                log("heartbeat angle=\(controller.lidAngle.map { "\(Int($0))" } ?? "nil") failures=\(controller.sensorFailures)")
            }
        }
    }
}
