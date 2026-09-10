import AppKit
import ImageIO
import UniformTypeIdentifiers

// Compile with the reusable renderer; see resources/branding-v1/menu-bar/README.md.
@main
struct MakeMenuIcons {
    static func bitmap(width: Int, height: Int, draw: () -> Void) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        memset(rep.bitmapData!, 0, rep.bytesPerRow * height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.shouldAntialias = true
        draw()
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    static func png(_ rep: NSBitmapImageRep, at url: URL) throws {
        try rep.representation(using: .png, properties: [:])!.write(to: url)
    }

    static func svg(angles: [Double]) -> String {
        let paths = angles.enumerated().map { index, degrees in
            let radians = degrees * .pi / 180
            let x = 147 + 264 * cos(radians)
            let y = 386 - 264 * sin(radians)
            return String(
                format: "  <path transform=\"translate(%d 0)\" d=\"M 411 386 L 147 386 L %.8f %.8f\"/>",
                index * 512, x, y
            )
        }.joined(separator: "\n")
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(angles.count * 512)" height="512" viewBox="0 0 \(angles.count * 512) 512">
        <g fill="none" stroke="#000000" stroke-width="24" stroke-linecap="round" stroke-linejoin="round">
        \(paths)
        </g>
        </svg>

        """
    }

    static func preview(angle: Double, size: Int, label: Bool) -> NSBitmapImageRep {
        bitmap(width: size, height: size) {
            NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
            NSRect(x: 0, y: 0, width: size, height: size).fill()
            FoldawayMenuIcon.draw(
                lidAngleDegrees: angle,
                in: NSRect(x: 0, y: 25, width: size, height: size)
            )
            if label {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular),
                    .foregroundColor: NSColor(calibratedWhite: 0.42, alpha: 1),
                ]
                let text = String(format: "%.1f°", angle) as NSString
                let width = text.size(withAttributes: attributes).width
                text.draw(at: NSPoint(x: (CGFloat(size) - width) / 2, y: 26), withAttributes: attributes)
            }
        }
    }

    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first
            ?? "resources/branding-v1/menu-bar")
        for folder in ["frames-512", "menu-18pt", "previews"] {
            try FileManager.default.createDirectory(
                at: output.appendingPathComponent(folder), withIntermediateDirectories: true
            )
        }
        let angles = FoldawayMenuIcon.frameAngles
        var manifest: [[String: Any]] = []
        var masterFrames: [NSBitmapImageRep] = []
        for (index, angle) in angles.enumerated() {
            let name = String(format: "frame-%02d", index + 1)
            let master = bitmap(width: 512, height: 512) {
                FoldawayMenuIcon.draw(lidAngleDegrees: angle, in: NSRect(x: 0, y: 0, width: 512, height: 512))
            }
            masterFrames.append(master)
            try png(master, at: output.appendingPathComponent("frames-512/\(name).png"))
            try svg(angles: [angle]).write(
                to: output.appendingPathComponent("frames-512/\(name).svg"), atomically: true, encoding: .utf8
            )
            for scale in [1, 2] {
                let pixels = 18 * scale
                let rep = bitmap(width: pixels, height: pixels) {
                    FoldawayMenuIcon.draw(
                        lidAngleDegrees: angle,
                        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
                        menuOptimized: true
                    )
                }
                rep.size = NSSize(width: 18, height: 18)
                try png(rep, at: output.appendingPathComponent("menu-18pt/\(name)\(scale == 2 ? "@2x" : "").png"))
            }
            manifest.append([
                "frame": index + 1, "angle_degrees": angle,
                "sprite_rect": [index * 512, 0, 512, 512],
                "png": "frames-512/\(name).png", "svg": "frames-512/\(name).svg",
                "menu_1x": "menu-18pt/\(name).png", "menu_2x": "menu-18pt/\(name)@2x.png",
            ])
        }
        let sprite = bitmap(width: 4608, height: 512) {}
        // Copy the existing pixels so each sprite slice is byte-identical to its PNG.
        for (index, frame) in masterFrames.enumerated() {
            for y in 0..<512 {
                memcpy(
                    sprite.bitmapData! + y * sprite.bytesPerRow + index * 512 * 4,
                    frame.bitmapData! + y * frame.bytesPerRow,
                    512 * 4
                )
            }
        }
        try png(sprite, at: output.appendingPathComponent("menu-fold-sprite-4608x512.png"))
        try svg(angles: angles).write(
            to: output.appendingPathComponent("menu-fold-sprite-4608x512.svg"), atomically: true, encoding: .utf8
        )

        let contact = bitmap(width: 900, height: 900) {
            for (index, angle) in angles.enumerated() {
                let rep = preview(angle: angle, size: 300, label: true)
                let image = NSImage(size: NSSize(width: 300, height: 300))
                image.addRepresentation(rep)
                image.draw(in: NSRect(x: (index % 3) * 300, y: (2 - index / 3) * 300, width: 300, height: 300))
            }
        }
        try png(contact, at: output.appendingPathComponent("previews/contact-sheet.png"))
        let animationAngles = angles + angles.dropFirst().dropLast().reversed()
        let gif = CGImageDestinationCreateWithURL(
            output.appendingPathComponent("previews/fold-animation.gif") as CFURL,
            UTType.gif.identifier as CFString, animationAngles.count, nil
        )!
        CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for angle in animationAngles {
            let rep = preview(angle: angle, size: 360, label: false)
            CGImageDestinationAddImage(gif, rep.cgImage!, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: angle == 0 || angle == 100 ? 0.5 : 0.09]
            ] as CFDictionary)
        }
        guard CGImageDestinationFinalize(gif) else { fatalError("GIF export failed") }
        let metadata: [String: Any] = [
            "format": "Foldaway menu template assets v1",
            "frame_count": 9, "frame_size_px": [512, 512],
            "sprite_size_px": [4608, 512], "rgb": "#000000", "background": "transparent",
            "stroke_width_master_px": 24, "line_cap": "round", "line_join": "round",
            "svg_hinge": [147, 386], "svg_base_end": [411, 386], "lid_length_px": 264,
            "menu_point_size": [18, 18], "menu_master_view_box": [64, 64, 384, 384],
            "menu_base_alignment": "Fixed pixel-aligned baseline; 15.5 px from top at 1x, 31 px at 2x",
            "frames": manifest,
            "previews_only": ["previews/contact-sheet.png", "previews/fold-animation.gif"],
        ]
        try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
            .write(to: output.appendingPathComponent("manifest.json"))
        print("Generated 9 SVG + 9 PNG master frames, 18 menu PNGs, PNG/SVG sprite sheets, 2 previews, and manifest in \(output.path)")
    }
}
