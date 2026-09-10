import CoreGraphics
import FoldawayCore

enum FoldMask {
    private static let width = 4

    static func image(pixelHeight: Int) -> CGImage? {
        let height = max(pixelHeight, 2)
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        for row in 0..<height {
            let edge = Double(row) / Double(height - 1)
            context.setFillColor(CGColor(gray: 1, alpha: FoldCurve.blurWeight(edge: edge)))
            context.fill(CGRect(x: 0, y: row, width: width, height: 1))
        }
        return context.makeImage()
    }
}
