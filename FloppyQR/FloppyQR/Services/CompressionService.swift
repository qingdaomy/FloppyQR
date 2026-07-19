import Foundation
import Compression

struct CompressionService {

    static func compress(_ data: Data) -> Data? {
        let bufSize = data.count + 64
        var deflated = Data(count: bufSize)
        let r = deflated.withUnsafeMutableBytes { d in
            data.withUnsafeBytes { s in
                compression_encode_buffer(
                    d.baseAddress!.assumingMemoryBound(to: UInt8.self), bufSize,
                    s.baseAddress!.assumingMemoryBound(to: UInt8.self), data.count,
                    nil, COMPRESSION_ZLIB)
            }
        }
        guard r > 0 else { return nil }
        var result = Data([0x78, 0x9C])
        result.append(deflated[..<r])
        var cs = adler32(data).bigEndian
        withUnsafeBytes(of: &cs) { result.append(contentsOf: $0) }
        return result
    }

    static func decompress(_ data: Data, originalSize: Int) -> Data? {
        let deflated = data.dropFirst(2).dropLast(4)
        var out = Data(count: originalSize)
        let r = out.withUnsafeMutableBytes { d in
            deflated.withUnsafeBytes { s in
                compression_decode_buffer(
                    d.baseAddress!.assumingMemoryBound(to: UInt8.self), originalSize,
                    s.baseAddress!.assumingMemoryBound(to: UInt8.self), deflated.count,
                    nil, COMPRESSION_ZLIB)
            }
        }
        guard r > 0 else { return nil }
        out.count = r; return out
    }

    private static func adler32(_ data: Data) -> UInt32 {
        var a: UInt32 = 1; var b: UInt32 = 0
        for byte in data { a = (a + UInt32(byte)) % 65521; b = (b + a) % 65521 }
        return (b << 16) | a
    }

    static func packFiles(_ files: [(name: String, data: Data)]) -> Data {
        var packed = Data()
        var count = UInt32(files.count).bigEndian
        withUnsafeBytes(of: &count) { packed.append(contentsOf: $0) }
        for (name, data) in files {
            let nd = name.data(using: .utf8)!
            var nl = UInt16(nd.count).bigEndian
            withUnsafeBytes(of: &nl) { packed.append(contentsOf: $0) }
            packed.append(nd)
            var dl = UInt32(data.count).bigEndian
            withUnsafeBytes(of: &dl) { packed.append(contentsOf: $0) }
            packed.append(data)
        }
        return packed
    }
}
