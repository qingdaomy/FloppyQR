import Foundation

struct DataPayloadBuilder {

    static func build(
        html: String,
        metadata: AppMetadata,
        appId: Data,
        strict: Bool
    ) -> Data? {
        guard let htmlData = html.data(using: .utf8) else { return nil }
        guard let compressed = CompressionService.compress(htmlData) else { return nil }

        var metaBlock = buildMetadataBlock(metadata)
        var payload = Data()

        var magic = UInt32(0xDA7A10DA).bigEndian
        withUnsafeBytes(of: &magic) { payload.append(contentsOf: $0) }

        payload.append(UInt8(1))

        let flags: UInt8 = (strict ? 0x01 : 0x00) | 0x02
        payload.append(flags)

        payload.append(appId)

        var origLen = UInt32(htmlData.count).bigEndian
        withUnsafeBytes(of: &origLen) { payload.append(contentsOf: $0) }

        var metaLen = UInt16(metaBlock.count).bigEndian
        withUnsafeBytes(of: &metaLen) { payload.append(contentsOf: $0) }

        payload.append(metaBlock)
        payload.append(compressed)

        return payload
    }

    private static func buildMetadataBlock(_ metadata: AppMetadata) -> Data {
        var block = Data()

        let nameData = metadata.name.data(using: .utf8) ?? Data()
        block.append(UInt8(min(nameData.count, 255)))
        block.append(nameData)

        let versionData = metadata.version.data(using: .utf8) ?? Data()
        block.append(UInt8(min(versionData.count, 255)))
        block.append(versionData)

        let developerData = metadata.developer.data(using: .utf8) ?? Data()
        block.append(UInt8(min(developerData.count, 255)))
        block.append(developerData)

        let icon = metadata.iconData ?? Data(repeating: 200, count: 32 * 32 * 4)

        var iconW = UInt32(32).littleEndian
        var iconH = UInt32(32).littleEndian
        var bpp = UInt32(4).littleEndian
        withUnsafeBytes(of: &iconW) { block.append(contentsOf: $0) }
        withUnsafeBytes(of: &iconH) { block.append(contentsOf: $0) }
        withUnsafeBytes(of: &bpp) { block.append(contentsOf: $0) }

        block.append(icon)

        return block
    }
}
