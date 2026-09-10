import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let size = CGFloat(pixels)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = size * 0.1
    let plate = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let platePath = NSBezierPath(roundedRect: plate, xRadius: plate.width * 0.225, yRadius: plate.width * 0.225)
    NSGradient(
        starting: NSColor(calibratedRed: 0.15, green: 0.18, blue: 0.27, alpha: 1),
        ending: NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.08, alpha: 1)
    )!.draw(in: platePath, angle: -90)

    let screen = plate.insetBy(dx: plate.width * 0.16, dy: plate.height * 0.2)
    let screenPath = NSBezierPath(roundedRect: screen, xRadius: screen.width * 0.07, yRadius: screen.width * 0.07)
    NSGradient(colorsAndLocations:
        (NSColor(calibratedRed: 0.99, green: 0.84, blue: 0.64, alpha: 1), 0.0),
        (NSColor(calibratedRed: 0.62, green: 0.66, blue: 0.82, alpha: 1), 0.42),
        (NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.16, alpha: 1), 1.0)
    )!.draw(in: screenPath, angle: 90)

    let hinge = NSRect(x: screen.minX, y: screen.minY - plate.height * 0.075, width: screen.width, height: plate.height * 0.035)
    NSColor(calibratedWhite: 0.88, alpha: 0.95).setFill()
    NSBezierPath(roundedRect: hinge, xRadius: hinge.height / 2, yRadius: hinge.height / 2).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try render(pixels: size * scale).write(to: outputDirectory.appendingPathComponent(name))
        entries.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: outputDirectory.appendingPathComponent("Contents.json"))
