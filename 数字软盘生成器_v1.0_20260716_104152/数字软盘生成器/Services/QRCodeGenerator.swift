import AppKit
import CoreImage

struct QRCodeGenerator {

    static func generate(from string: String, size: CGFloat = 1000) -> NSImage? {
        guard let (cgImage, _) = generateCGImage(from: string, size: size) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    static func pngData(from string: String, size: CGFloat = 1000) -> Data? {
        guard let (cgImage, _) = generateCGImage(from: string, size: size) else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .png, properties: [:])
    }

    private static func generateCGImage(from string: String, size: CGFloat) -> (CGImage, CIImage)? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(string.data(using: .utf8), forKey: "inputMessage")
        filter?.setValue("L", forKey: "inputCorrectionLevel")

        guard let output = filter?.outputImage else { return nil }

        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext(options: [.highQualityDownsample: true])
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        return (cgImage, scaled)
    }
}
