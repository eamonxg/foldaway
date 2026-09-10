#!/usr/bin/env swift
import AppKit
import ImageIO
import UniformTypeIdentifiers

// Resample an approved, transparent square PNG into native macOS icon resources.
// This exporter never synthesizes artwork, masks the plate, or repairs source alpha.
guard CommandLine.arguments.count == 3 else {
    fputs("Usage: swift scripts/export-app-icon.swift SOURCE.png OUTPUT_DIRECTORY\n", stderr)
    exit(1)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true).standardizedFileURL
let fm = FileManager.default
let sourceData = try Data(contentsOf: sourceURL)
guard let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
      sourceImage.width == sourceImage.height else {
    fatalError("Expected a readable square source image")
}
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let iconsetURL = outputURL.appendingPathComponent("Foldaway.iconset", isDirectory: true)
let assetURL = outputURL.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
for url in [outputURL, iconsetURL, assetURL] {
    try fm.createDirectory(at: url, withIntermediateDirectories: true)
}
try sourceData.write(to: outputURL.appendingPathComponent("source-generated.png"))

func render(pixels: Int) -> Data {
    guard let context = CGContext(
        data: nil, width: pixels, height: pixels,
        bitsPerComponent: 8, bytesPerRow: pixels * 4, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("Could not create the export bitmap") }
    context.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    guard let image = context.makeImage() else { fatalError("Could not finish the export bitmap") }
    let png = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(png, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Could not create PNG encoder")
    }
    CGImageDestinationAddImage(destination, image, [kCGImagePropertyDPIWidth: 72, kCGImagePropertyDPIHeight: 72] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fatalError("Could not encode PNG") }
    return png as Data
}

var rendered: [Int: Data] = [:]
var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        if rendered[pixels] == nil { rendered[pixels] = render(pixels: pixels) }
        let png = rendered[pixels]!
        try png.write(to: iconsetURL.appendingPathComponent(filename))
        try png.write(to: assetURL.appendingPathComponent(filename))
        entries.append(["filename": filename, "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
try rendered[1024]!.write(to: outputURL.appendingPathComponent("AppIcon.png"))
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: assetURL.appendingPathComponent("Contents.json"))

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", outputURL.appendingPathComponent("Foldaway.icns").path, iconsetURL.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Exported \(sourceImage.width)×\(sourceImage.height) source into AppIcon.png, 10 catalog PNGs, 10 iconset PNGs, and Foldaway.icns at \(outputURL.path)")
