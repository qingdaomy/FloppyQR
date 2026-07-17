import Foundation
import Compression

struct CompressionService {

    static func compress(_ data: Data) -> Data? {
        let destinationSize = data.count + 64
        var compressed = Data(count: destinationSize)
        let result = compressed.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                compression_encode_buffer(
                    dst.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    src.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard result != 0 else { return nil }
        compressed.count = result
        return compressed
    }

    static func decompress(_ data: Data, originalSize: Int) -> Data? {
        var decompressed = Data(count: originalSize)
        let result = decompressed.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                compression_decode_buffer(
                    dst.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    originalSize,
                    src.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard result != 0 else { return nil }
        decompressed.count = result
        return decompressed
    }
}
