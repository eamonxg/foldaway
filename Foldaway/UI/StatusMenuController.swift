import AppKit
import ServiceManagement
import FoldawayCore

final class StatusMenuController: NSObject, NSMenuDelegate {
    private let controller: FoldController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let angleItem = NSMenuItem()
    private let enabledItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private let startSlider: SliderMenuItem
    private let endSlider: SliderMenuItem
    private let blurSlider: SliderMenuItem

    init(controller: FoldController) {
        self.controller = controller
        let settings = controller.settings
        startSlider = SliderMenuItem(title: String(localized: "Start Angle"), range: FoldSettings.startAngleRange, value: settings.startAngle, format: "%.0f°")
        endSlider = SliderMenuItem(title: String(localized: "End Angle"), range: FoldSettings.endAngleRange, value: settings.endAngle, format: "%.0f°")
        blurSlider = SliderMenuItem(title: String(localized: "Blur Strength"), range: FoldSettings.maxBlurRadiusRange, value: settings.maxBlurRadius, format: "%.0f pt")
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "Foldaway")
        statusItem.menu = makeMenu()
        controller.onLidAngleChange = { [weak self] angle in self?.updateAngleItem(angle) }
        updateAngleItem(controller.lidAngle)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        enabledItem.state = controller.settings.isEnabled ? .on : .off
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(angleItem)
        if !controller.isBlurSupported {
            menu.addItem(NSMenuItem(title: String(localized: "Blur unavailable on this macOS, darkening only"), action: nil, keyEquivalent: ""))
        }
        menu.addItem(.separator())
        enabledItem.title = String(localized: "Enabled")
        enabledItem.target = self
        enabledItem.action = #selector(toggleEnabled)
        menu.addItem(enabledItem)
        let previewItem = NSMenuItem(title: String(localized: "Preview Fold"), action: #selector(previewFold), keyEquivalent: "p")
        previewItem.target = self
        menu.addItem(previewItem)
        menu.addItem(.separator())
        for slider in [startSlider, endSlider, blurSlider] {
            slider.onChange = { [weak self] in self?.applySliders() }
            menu.addItem(slider)
        }
        menu.addItem(.separator())
        launchAtLoginItem.title = String(localized: "Launch at Login")
        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: String(localized: "Quit Foldaway"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    private func updateAngleItem(_ angle: Double?) {
        if let angle {
            angleItem.title = String(format: String(localized: "Lid angle: %.0f°"), angle)
        } else {
            angleItem.title = controller.isSensorAvailable ? String(localized: "Lid angle: reading…") : String(localized: "Lid angle sensor not found")
        }
    }

    private func applySliders() {
        var settings = controller.settings
        settings.startAngle = startSlider.value.rounded()
        settings.endAngle = endSlider.value.rounded()
        settings.maxBlurRadius = blurSlider.value.rounded()
        let normalized = settings.normalized()
        controller.settings = normalized
        startSlider.setValue(normalized.startAngle)
        endSlider.setValue(normalized.endAngle)
        blurSlider.setValue(normalized.maxBlurRadius)
    }

    @objc private func toggleEnabled() {
        controller.settings.isEnabled.toggle()
    }

    @objc private func previewFold() {
        controller.startPreview()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Launch at Login change failed: %@", error.localizedDescription)
        }
    }
}
