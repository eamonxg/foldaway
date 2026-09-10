import AppKit

/// A monochrome status-item image. All frames share the same hinge and base.
/// The angle is measured counterclockwise from the base: 0° is closed.
public enum FoldawayMenuIcon {
    public static let frameAngles: [Double] = (0..<9).map { 100 - Double($0) * 12.5 }

    /// Accepts a live sensor angle; absent or non-finite readings use the open pose.
    /// Values outside the illustrated 0...100° range are clamped.
    public static func image(
        lidAngleDegrees: Double?,
        pointSize: CGFloat = 18
    ) -> NSImage {
        let size = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(size: size, flipped: false) { rect in
            draw(lidAngleDegrees: lidAngleDegrees, in: rect, menuOptimized: true)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Foldaway"
        return image
    }

    /// Draws pure black paths; antialiasing affects only alpha on transparent targets.
    /// Master exports use a 512-unit square. Menu exports use a fixed 384-unit crop
    /// to retain a readable 1.125 pt stroke at 18 pt, without shifting between frames.
    public static func draw(
        lidAngleDegrees: Double?,
        in rect: NSRect,
        menuOptimized: Bool = false
    ) {
        let value = lidAngleDegrees.flatMap { $0.isFinite ? $0 : nil } ?? 100
        let angle = min(100, max(0, value)) * .pi / 180
        let viewport = menuOptimized
            ? NSRect(x: 64, y: 64, width: 384, height: 384)
            : NSRect(x: 0, y: 0, width: 512, height: 512)
        let scale = min(rect.width / viewport.width, rect.height / viewport.height)
        let hinge = NSPoint(x: 147, y: 126)
        let end = NSPoint(x: 411, y: 126)
        let lid = NSPoint(
            x: hinge.x + 264 * cos(angle),
            y: hinge.y + 264 * sin(angle)
        )

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = AffineTransform(
            scaleByX: scale,
            byY: scale
        )
        let offsetX = rect.midX - viewport.midX * scale
        var offsetY = rect.midY - viewport.midY * scale
        if menuOptimized {
            // Keep the fixed base crisp at both 18 px and 36 px.
            let baseY = hinge.y * scale + offsetY
            let halfPixel = Int((24 * scale).rounded()).isMultiple(of: 2) ? 0.0 : 0.5
            offsetY += floor(baseY) + halfPixel - baseY
        }
        let path = NSBezierPath()
        path.move(to: end)
        path.line(to: hinge)
        path.line(to: lid)
        path.transform(using: transform)
        path.transform(using: AffineTransform(translationByX: offsetX, byY: offsetY))
        path.lineWidth = 24 * scale
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        NSColor.black.setStroke()
        path.stroke()
    }
}
