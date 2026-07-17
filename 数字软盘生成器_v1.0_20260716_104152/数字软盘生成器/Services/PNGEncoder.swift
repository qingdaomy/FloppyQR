import Foundation
import Compression

struct PNGEncoder {

    static func createDataDisk(payload: Data, width: Int = 1024, height: Int = 1024) -> Data {
        var png = Data()

        let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        png.append(contentsOf: signature)

        var ihdr = Data()
        var w = UInt32(width).bigEndian
        var h = UInt32(height).bigEndian
        withUnsafeBytes(of: &w) { ihdr.append(contentsOf: $0) }
        withUnsafeBytes(of: &h) { ihdr.append(contentsOf: $0) }
        ihdr.append(contentsOf: [8, 6, 0, 0, 0])
        png.append(contentsOf: makeChunk(type: "IHDR", data: ihdr))

        png.append(contentsOf: makeChunk(type: "zDAT", data: payload))

        let imageData = createWhiteImageData(width: width, height: height)
        if let compressed = compressIDAT(imageData) {
            png.append(contentsOf: makeChunk(type: "IDAT", data: compressed))
        }

        png.append(contentsOf: makeChunk(type: "IEND", data: Data()))

        return png
    }

    private static func makeChunk(type: String, data: Data) -> Data {
        var chunk = Data()
        var len = UInt32(data.count).bigEndian
        withUnsafeBytes(of: &len) { chunk.append(contentsOf: $0) }
        let typeData = type.data(using: .ascii)!
        chunk.append(typeData)
        chunk.append(data)
        var crc = crc32(data: typeData + data).bigEndian
        withUnsafeBytes(of: &crc) { chunk.append(contentsOf: $0) }
        return chunk
    }

    private static func createWhiteImageData(width: Int, height: Int) -> Data {
        var data = Data(capacity: height * (1 + width * 4))
        let row = Data(repeating: 255, count: width * 4)
        for _ in 0..<height {
            data.append(0)
            data.append(row)
        }
        return data
    }

    private static func compressIDAT(_ data: Data) -> Data? {
        let destSize = data.count + 64
        var compressed = Data(count: destSize)
        let result = compressed.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                compression_encode_buffer(
                    dst.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destSize,
                    src.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard result > 0 else { return nil }
        compressed.count = result
        return compressed
    }

    private static func crc32(data: Data) -> UInt32 {
        var table = [UInt32](repeating: 0, count: 256)
        for n in 0..<256 {
            var c = UInt32(n)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            table[n] = c
        }
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}
