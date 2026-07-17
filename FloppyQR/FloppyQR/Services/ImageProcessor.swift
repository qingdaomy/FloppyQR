import AppKit

struct ImageProcessor {

    static func processIcon(_ image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let w = 32, h = 32
        let cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let ctx, let data = ctx.data else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return Data(bytes: data, count: w * h * 4)
    }

    /// Returns the FloppyQR app icon as 32x32 RGBA data.
    /// Used as the default icon on Floppy PNG when user doesn't provide one.
    static func placeholderIcon() -> Data {
        // Load the app icon from bundle
        if let iconImage = NSImage(named: "AppIcon") {
            if let data = processIcon(iconImage) {
                return data
            }
        }
        // Fallback: gray placeholder
        return Data(repeating: 200, count: 32 * 32 * 4)
    }
}
