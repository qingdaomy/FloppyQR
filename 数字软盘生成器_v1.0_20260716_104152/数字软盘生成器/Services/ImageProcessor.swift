import AppKit

struct ImageProcessor {

    static func processIcon(_ image: NSImage) -> Data? {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 32,
            pixelsHigh: 32,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 32 * 4,
            bitsPerPixel: 32
        )

        guard let bitmap else { return nil }

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current = context

        image.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.bitmapData else { return nil }
        return Data(bytes: data, count: 32 * 32 * 4)
    }

    static func placeholderIcon() -> Data {
        Data(repeating: 200, count: 32 * 32 * 4)
    }
}
