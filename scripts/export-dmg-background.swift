#!/usr/bin/env swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

// Export the approved generated artwork, then typeset the installation instruction
// with the macOS system font. Run from the repository root:
// swift scripts/export-dmg-background.swift [source.png] [output-directory]
let fileManager = FileManager.default
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.count > 2
    ? CommandLine.arguments[2] : "resources/branding-v1/dmg", isDirectory: true)
let sourceURL = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : outputDirectory.appendingPathComponent("source-generated.png")

func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
    fail("Unable to read source image: \(sourceURL.path)")
}
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
let preservedSource = outputDirectory.appendingPathComponent("source-generated.png")
if sourceURL.standardizedFileURL != preservedSource.standardizedFileURL {
    if fileManager.fileExists(atPath: preservedSource.path) {
        try fileManager.removeItem(at: preservedSource)
    }
    try fileManager.copyItem(at: sourceURL, to: preservedSource)
}

let logicalSize = CGSize(width: 660, height: 400)
let font = NSFont.systemFont(ofSize: 14, weight: .medium)
let instruction = "Drag Foldaway to Applications"
let textColor = NSColor(srgbRed: 0.72, green: 0.75, blue: 0.81, alpha: 1)
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func render(scale: Int, withInstruction: Bool) -> CGImage {
    let width = Int(logicalSize.width) * scale
    let height = Int(logicalSize.height) * scale
    guard let context = CGContext(data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        fail("Unable to create \(width) × \(height) drawing context")
    }
    context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    context.interpolationQuality = .high
    context.draw(sourceImage, in: CGRect(origin: .zero, size: logicalSize))

    if withInstruction {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        let text = NSAttributedString(string: instruction, attributes: [
            .font: font,
            .foregroundColor: textColor,
            .kern: 0.12
        ])
        let size = text.size()
        // The center is (330, 330) in Finder's top-left-origin logical canvas.
        text.draw(at: CGPoint(x: (logicalSize.width - size.width) / 2,
                              y: logicalSize.height - 330 - size.height / 2))
        NSGraphicsContext.restoreGraphicsState()
    }
    guard let result = context.makeImage() else { fail("Unable to render background") }
    return result
}

func save(_ image: CGImage, scale: Int, name: String, type: UTType) {
    let url = outputDirectory.appendingPathComponent(name)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
        type.identifier as CFString, 1, nil) else { fail("Unable to write \(url.path)") }
    CGImageDestinationAddImage(destination, image, [
        kCGImagePropertyDPIWidth: 72 * scale,
        kCGImagePropertyDPIHeight: 72 * scale
    ] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fail("Export failed: \(name)") }
}

for scale in [1, 2] {
    let suffix = scale == 2 ? "@2x" : ""
    save(render(scale: scale, withInstruction: false), scale: scale,
         name: "background-no-text\(suffix).png", type: .png)
    let finalImage = render(scale: scale, withInstruction: true)
    save(finalImage, scale: scale, name: "background\(suffix).png", type: .png)
    save(finalImage, scale: scale, name: ".background\(suffix).tiff", type: .tiff)
}

// Finder can select the appropriate representation for the display density.
let tiffutil = Process()
tiffutil.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
tiffutil.arguments = ["-cathidpicheck",
    outputDirectory.appendingPathComponent(".background.tiff").path,
    outputDirectory.appendingPathComponent(".background@2x.tiff").path,
    "-out", outputDirectory.appendingPathComponent("background.tiff").path]
try tiffutil.run()
tiffutil.waitUntilExit()
guard tiffutil.terminationStatus == 0 else { fail("Unable to combine Retina TIFF") }
for temporary in [".background.tiff", ".background@2x.tiff"] {
    try fileManager.removeItem(at: outputDirectory.appendingPathComponent(temporary))
}

let layout: [String: Any] = [
    "coordinate_system": "logical points, top-left origin",
    "window": ["width": 660, "height": 400],
    "finder_icons": [
        "size": 96,
        "app_center": ["x": 180, "y": 160],
        "applications_center": ["x": 480, "y": 160]
    ],
    "artwork_recess_centers_approximate": [
        ["x": 185, "y": 160], ["x": 475, "y": 160]
    ],
    "instruction": [
        "text": instruction,
        "center": ["x": 330, "y": 330],
        "font_api": "NSFont.systemFont(ofSize: 14, weight: .medium)",
        "resolved_font": font.fontName,
        "font_size_points": 14,
        "tracking_points": 0.12,
        "color_srgb": [0.72, 0.75, 0.81, 1.0]
    ],
    "artwork_contains_app_or_folder_icons": false,
    "source_pixels": ["width": sourceImage.width, "height": sourceImage.height],
    "exports": [
        "background.png": ["width": 660, "height": 400, "dpi": 72],
        "background@2x.png": ["width": 1320, "height": 800, "dpi": 144],
        "background-no-text.png": ["width": 660, "height": 400, "dpi": 72],
        "background-no-text@2x.png": ["width": 1320, "height": 800, "dpi": 144]
    ],
    "finder_background": "background.tiff (1x and 2x representations)"
]
let layoutData = try JSONSerialization.data(withJSONObject: layout,
                                            options: [.prettyPrinted, .sortedKeys])
try layoutData.write(to: outputDirectory.appendingPathComponent("layout.json"))
print("Exported DMG backgrounds to \(outputDirectory.path)")
print("System font: \(font.fontName), 14 pt medium")
