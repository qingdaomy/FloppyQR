import Foundation
import AppKit

struct PNGEncoder {

    static func createDataDisk(payload: Data, originalImage: NSImage? = nil, width: Int = 1024, height: Int = 1024, zLDR: Data? = nil) -> Data {
        var raw = Data(count: width * height * 4)
        raw.withUnsafeMutableBytes { (rp: UnsafeMutableRawBufferPointer) in
            let ptr = rp.baseAddress!.assumingMemoryBound(to: UInt8.self)
            // Fill white
            for i in 0..<(width*height) {
                let off = i * 4
                ptr[off] = 255; ptr[off+1] = 255
                ptr[off+2] = 255; ptr[off+3] = 255
            }
            // Draw icon centered (256x256) with smooth scaling
            do {
                let iw = 256, ih = 256
                let ox = (width - iw) / 2, oy = (height - ih) / 2
                let cs = CGColorSpaceCreateDeviceRGB()
                if let cgCtx = CGContext(
                    data: nil, width: iw, height: ih,
                    bitsPerComponent: 8, bytesPerRow: iw * 4,
                    space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ), let cgData = cgCtx.data {
                    if let cgImg = originalImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        cgCtx.draw(cgImg, in: CGRect(x: 0, y: 0, width: iw, height: ih))
                    } else {
                        let r = CGRect(x: 14, y: 14, width: iw - 28, height: ih - 28)
                        let p = CGPath(roundedRect: r, cornerWidth: 44, cornerHeight: 44, transform: nil)
                        cgCtx.addPath(p)
                        cgCtx.setFillColor(CGColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1))
                        cgCtx.fillPath()
                    }
                    let src = cgData.assumingMemoryBound(to: UInt8.self)
                    for y in 0..<ih {
                        for x in 0..<iw {
                            let sp = (y * iw + x) * 4
                            let a = src[sp + 3]
                            if a > 0 {
                                let dp = ((oy + y) * width + (ox + x)) * 4
                                if a == 255 {
                                    ptr[dp] = src[sp]; ptr[dp+1] = src[sp+1]; ptr[dp+2] = src[sp+2]
                                } else {
                                    let f = Float(a) / 255.0
                                    ptr[dp] = UInt8(Float(src[sp]) + 255.0 * (1-f))
                                    ptr[dp+1] = UInt8(Float(src[sp+1]) + 255.0 * (1-f))
                                    ptr[dp+2] = UInt8(Float(src[sp+2]) + 255.0 * (1-f))
                                }
                            }
                        }
                    }
                }
            }
        }

        // Convert to PNG via NSBitmapImageRep
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4, bitsPerPixel: 32
        )
        if let bitmap, let base = bitmap.bitmapData {
            raw.copyBytes(to: base, count: raw.count)
            if let pngData = bitmap.representation(using: .png, properties: [:]) {
                var result = Data()
                result.append(pngData)
                if let iend = result.range(of: "IEND".data(using: .ascii)!, options: .backwards) {
                    let pos = iend.lowerBound - 4
                    result.insert(contentsOf: makeChunk("zDAT", payload), at: pos)
                    if let ld = zLDR {
                        let ldPos = result.range(of: "IEND".data(using: .ascii)!, options: .backwards)!.lowerBound - 4
                        result.insert(contentsOf: makeChunk("zLDR", ld), at: ldPos)
                    }
                }
                return result
            }
        }

        // Fallback: just return raw data with zDAT
        var png = Data()
        png.append(contentsOf: [137, 80, 78, 71, 13, 10, 26, 10])
        var ihdr = Data()
        var w = UInt32(width).bigEndian; var h = UInt32(height).bigEndian
        withUnsafeBytes(of: &w) { ihdr.append(contentsOf: $0) }
        withUnsafeBytes(of: &h) { ihdr.append(contentsOf: $0) }
        ihdr.append(contentsOf: [8, 6, 0, 0, 0])
        png.append(makeChunk("IHDR", ihdr))
        png.append(makeChunk("zDAT", payload))
        var sc = Data()
        for y in 0..<height { sc.append(0); sc.append(raw[(y*width*4)..<((y+1)*width*4)]) }
        png.append(makeChunk("IDAT", sc))
        png.append(makeChunk("IEND", Data()))
        return png
    }

    private static func makeChunk(_ type: String, _ data: Data) -> Data {
        var c = Data()
        var l = UInt32(data.count).bigEndian
        withUnsafeBytes(of: &l) { c.append(contentsOf: $0) }
        let td = type.data(using: .ascii)!
        c.append(td); c.append(data)
        var cr = crc32(td + data).bigEndian
        withUnsafeBytes(of: &cr) { c.append(contentsOf: $0) }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var t = [UInt32](repeating: 0, count: 256)
        for n in 0..<256 { var c = UInt32(n); for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }; t[n] = c }
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data { crc = t[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8) }
        return crc ^ 0xFFFFFFFF
    }
}
