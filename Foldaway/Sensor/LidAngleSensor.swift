import Foundation
import IOKit.hid

final class LidAngleSensor {
    private static let vendorID = 0x05AC
    private static let productID = 0x8104
    private static let usagePage = 0x0020
    private static let usage = 0x008A
    private static let reportID: CFIndex = 1
    private static let reportLength = 8
    private static let failuresBeforeReprobe = 120
    private static let options = IOOptionBits(kIOHIDOptionsTypeNone)

    private(set) var isAvailable = false
    private(set) var lastResult: IOReturn = kIOReturnSuccess
    private(set) var lastReport: [UInt8] = []
    private var device: IOHIDDevice?
    private var isOpen = false
    private var report = [UInt8](repeating: 0, count: LidAngleSensor.reportLength)
    private(set) var consecutiveFailures = 0

    init() {
        probe()
    }

    deinit {
        close()
    }

    func read() -> Double? {
        if consecutiveFailures >= Self.failuresBeforeReprobe { probe() }
        guard let device else { return recordFailure() }
        if !isOpen {
            let opened = IOHIDDeviceOpen(device, Self.options)
            lastResult = opened
            guard opened == kIOReturnSuccess else { return recordFailure() }
            isOpen = true
        }
        var length = CFIndex(report.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, Self.reportID, &report, &length)
        lastResult = result
        lastReport = Array(report.prefix(max(0, min(Int(length), report.count))))
        guard result == kIOReturnSuccess, length >= 3 else { return recordFailure() }
        consecutiveFailures = 0
        return Double(UInt16(report[2]) << 8 | UInt16(report[1]))
    }

    private func recordFailure() -> Double? {
        consecutiveFailures += 1
        return nil
    }

    private func probe() {
        close()
        consecutiveFailures = 0
        device = Self.findDevice()
        isAvailable = device != nil
    }

    private func close() {
        if isOpen, let device { IOHIDDeviceClose(device, Self.options) }
        isOpen = false
    }

    private static func findDevice() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, options)
        let matching: [String: Any] = [kIOHIDVendorIDKey: vendorID, kIOHIDProductIDKey: productID]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        guard IOHIDManagerOpen(manager, options) == kIOReturnSuccess else { return nil }
        defer { IOHIDManagerClose(manager, options) }
        let devices = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>) ?? []
        return devices.first { device in
            intProperty(device, kIOHIDPrimaryUsagePageKey) == usagePage && intProperty(device, kIOHIDPrimaryUsageKey) == usage
        }
    }

    private static func intProperty(_ device: IOHIDDevice, _ key: String) -> Int? {
        IOHIDDeviceGetProperty(device, key as CFString) as? Int
    }
}
