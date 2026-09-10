import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
let width = 660.0
let height = 400.0

func render(scale: CGFloat) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()

    NSGradient(starting: NSColor(calibratedWhite: 0.98, alpha: 1), ending: NSColor(calibratedWhite: 0.93, alpha: 1))!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    let y = height - 185
    let shaft = NSBezierPath()
    shaft.move(to: NSPoint(x: 262, y: y))
    shaft.line(to: NSPoint(x: 392, y: y))
    shaft.lineWidth = 7
    shaft.lineCapStyle = .round
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 372, y: y + 20))
    head.line(to: NSPoint(x: 398, y: y))
    head.line(to: NSPoint(x: 372, y: y - 20))
    head.lineWidth = 7
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    NSColor(calibratedWhite: 0.6, alpha: 1).setStroke()
    shaft.stroke()
    head.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try render(scale: 1).write(to: outputDirectory.appendingPathComponent("background.png"))
try render(scale: 2).write(to: outputDirectory.appendingPathComponent("background@2x.png"))
