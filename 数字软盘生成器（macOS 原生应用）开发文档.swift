数字软盘生成器（macOS 原生应用）开发文档
1. 项目概述
目标：开发一款 macOS 原生应用，允许用户：

输入 HTML 代码（或选择 HTML 文件）；

填写应用元数据（应用名称、版本、开发者、图标）；

一键生成：

一张 启动头二维码（内含加载器及配对信息）；

一张（或多张） 数据盘 PNG 图片（使用 LSB 隐写存储压缩后的 HTML 代码，并嵌入元数据）。

生成的二维码和数据盘可直接用于离线分发。

技术栈：

语言：Swift

UI 框架：SwiftUI (macOS 12+)

二维码生成：CoreImage (CIFilter + CIQRCodeGenerator)

图片处理：AppKit (NSImage, NSBitmapImageRep)

压缩：zlib（通过 Data 的 compress/decompress 或使用 Compression 框架）

隐写：自定义像素位操作

2. 功能需求
2.1 主窗口（生成器）
代码输入区域：可编辑的文本区，支持粘贴 HTML 代码，或通过“打开文件”按钮加载 .html 文件。

元数据表单：

应用名称（文本输入框）

版本号（文本输入框）

开发者名称（文本输入框）

应用图标（拖拽或选择图片，自动缩放为 32×32 像素，导出为 RGBA 原始数据）

生成按钮：点击后执行以下操作：

压缩 HTML 代码（zlib）；

构建数据盘头部（含元数据）；

创建 1024×1024 的 PNG 图片，将数据写入每个像素的 RGBA 通道低 2 位（可配置）；

生成启动头二维码（包含配对 ID 和加载器 HTML）；

弹出保存对话框，分别保存二维码和数据盘图片（可命名）。

预览：可选显示生成的二维码缩略图。

2.2 高级选项（可折叠）
严格配对开关：是否强制启动头与数据盘 ID 匹配。

每通道位数：1~4，控制数据容量（默认为 2）。

加密选项：预留 AES 加密（后续扩展）。

2.3 输出
启动头二维码：.png，内容为 data:text/html,{加载器HTML}。

数据盘图片：.png，内含完整应用数据。

3. 数据规范（详细定义）
3.1 启动头二维码内容
二维码扫描后得到的是一段 Data URI，指向一个自包含的加载器 HTML 页面。该页面中嵌入了一个 JSON 对象（可通过 JavaScript 变量或隐藏元素存储），包含以下字段：

json
{
  "appId": "a1b2c3d4e5f67890...",   // 16字节随机Hex，与数据盘配对
  "strict": true/false,
  "version": "1.0"
}
加载器 HTML 负责：读取用户选中的图片，解析数据盘，验证配对，解压并运行应用。

3.2 数据盘图片结构
3.2.1 数据盘二进制布局（按顺序写入像素低 bit 位）
字段	大小	说明
魔数	4 字节	固定 0xDA7A10DA
版本	1 字节	当前为 0x01
标志	1 字节	bit0: 加密，bit1: 压缩（必为1），其余保留
应用ID	16 字节	二进制，与启动头一致
原始数据长度	4 字节	解压后的字节数（无符号大端）
元数据长度	2 字节	紧随其后的元数据总字节数
元数据块	变长	包含应用名称和图标（格式见下）
压缩数据	变长	zlib 压缩后的 HTML 代码
3.2.2 元数据块格式
长度	内容
1 字节	名称长度 N（1~255）
N 字节	应用名称（UTF-8）
4 字节	图标宽度（固定 32，小端）
4 字节	图标高度（固定 32）
4 字节	图标每像素字节数（固定 4，RGBA）
4096 字节	图标原始 RGBA 数据（32×32×4）
3.3 图片生成参数
尺寸：1024×1024

位深：每个像素 RGBA 四个通道，每个通道存储 BITS_PER_CHANNEL 位（默认 2）

容量：1024×1024×4×BITS_PER_CHANNEL / 8 字节

2 bit → 1 MB

4 bit → 2 MB

8 bit → 4 MB（此时图片可能偏色严重）

4. UI 设计（SwiftUI 布局）
text
+---------------------------------------------------+
|  数字软盘生成器  —  □  ×                         |
+---------------------------------------------------+
|  📄 HTML 代码                                      |
|  +---------------------------------------------+  |
|  | (多行文本框)                                 |  |
|  |                                             |  |
|  +---------------------------------------------+  |
|  [打开文件] [清空]                                 |
|                                                   |
|  应用信息                                          |
|  名称: [________________]  版本: [______]          |
|  开发者: [________________]                        |
|  图标: [选择图标] (显示32×32预览)                 |
|                                                   |
|  ⚙️ 高级选项 [展开▼]                              |
|    严格配对: [✓]  每通道位数: [2]  (1-4)         |
|                                                   |
|  [生成]  [生成并保存...]                           |
|                                                   |
|  状态: 准备就绪                                    |
+---------------------------------------------------+
5. 核心实现步骤（Swift 代码要点）
5.1 压缩与编码
swift
import Compression

func compressHTML(_ html: String) -> Data? {
    guard let data = html.data(using: .utf8) else { return nil }
    // 使用 Compression 框架进行 zlib 压缩
    let compressed = try? (data as NSData).compressed(using: .zlib) as Data
    return compressed
}
5.2 构建二进制数据
swift
func buildDataPayload(html: String, meta: (name: String, iconData: Data), appId: Data) -> Data {
    var payload = Data()
    // 魔数
    payload.append(contentsOf: [0xDA, 0x7A, 0x10, 0xDA])
    // 版本
    payload.append(0x01)
    // 标志 (压缩标志位)
    payload.append(0x02) // bit1=1 表示已压缩
    // 应用ID
    payload.append(appId)
    // 原始长度 (占位，稍后填写)
    let origLen = html.utf8.count
    payload.append(contentsOf: withUnsafeBytes(of: UInt32(origLen).bigEndian) { Data($0) })
    // 元数据长度占位
    // 构建元数据
    var metaData = Data()
    let nameBytes = meta.name.data(using: .utf8)!
    metaData.append(UInt8(nameBytes.count))
    metaData.append(nameBytes)
    // 图标尺寸固定
    metaData.append(contentsOf: withUnsafeBytes(of: UInt32(32).littleEndian) { Data($0) })
    metaData.append(contentsOf: withUnsafeBytes(of: UInt32(32).littleEndian) { Data($0) })
    metaData.append(contentsOf: withUnsafeBytes(of: UInt32(4).littleEndian) { Data($0) })
    metaData.append(meta.iconData)
    // 写入元数据长度
    let metaLen = UInt16(metaData.count)
    payload.append(contentsOf: withUnsafeBytes(of: metaLen.bigEndian) { Data($0) })
    payload.append(metaData)
    // 压缩数据
    let compressed = compressHTML(html)!
    payload.append(compressed)
    return payload
}
5.3 写入像素（LSB 隐写）
swift
func encodeDataToPNG(_ data: Data, bitsPerChannel: Int, size: Int) -> NSImage? {
    let totalBits = size * size * 4 * bitsPerChannel
    // 将 data 转为二进制字符串（高位优先）
    var bitString = ""
    for byte in data {
        bitString += String(byte, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0)
    }
    // 补齐
    while bitString.count < totalBits {
        bitString += "0"
    }
    // 创建像素数组
    var pixelData = [UInt8](repeating: 255, count: size * size * 4)
    var idx = 0
    for i in 0..<pixelData.count {
        let bits = bitString[idx..<idx+bitsPerChannel]
        let val = UInt8(bits, radix: 2)!
        // 清除低 bitsPerChannel 位
        pixelData[i] = (pixelData[i] & (0xFF << bitsPerChannel)) | val
        idx += bitsPerChannel
    }
    // 创建 NSImage
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                  pixelsWide: size,
                                  pixelsHigh: size,
                                  bitsPerSample: 8,
                                  samplesPerPixel: 4,
                                  hasAlpha: true,
                                  isPlanar: false,
                                  colorSpaceName: .deviceRGB,
                                  bytesPerRow: size * 4,
                                  bitsPerPixel: 32)
    memcpy(bitmap?.bitmapData, pixelData, pixelData.count)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmap!)
    return image
}
5.4 生成二维码
swift
import CoreImage

func generateQRCode(from string: String) -> NSImage? {
    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(string.data(using: .utf8), forKey: "inputMessage")
    filter?.setValue("H", forKey: "inputCorrectionLevel")
    if let output = filter?.outputImage {
        let scaleX = 300 / output.extent.width
        let scaleY = 300 / output.extent.height
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
    return nil
}
5.5 加载器 HTML（嵌入启动头）
加载器 HTML 内容较长，但核心逻辑是：

读取用户选择的图片，提取低 bit 位还原数据；

解析头部，提取应用ID、元数据；

与启动头中的 appId 比较（若 strict）；

解压并执行 HTML。

我们将其作为字符串模板，嵌入二维码。

6. 开发流程（建议）
创建 Xcode 项目：选择 macOS > App，使用 SwiftUI。

设计 UI：使用 Form、TextEditor、TextField、Button 等构建主窗口。

实现核心功能：

压缩与编码逻辑

图片生成与保存

二维码生成

加载器 HTML 模板（可作为资源文件或字符串常量）

集成文件选择与保存：使用 NSOpenPanel 和 NSSavePanel。

测试：生成一组数据，用手机扫码测试加载器是否能正常打开并运行应用。

打包发布：使用 Xcode 的 Archive 功能生成 .app 或 .dmg。

7. 注意事项
容量限制：如果 HTML 过大，可提示用户减少代码或增加每通道位数。

图片质量：当 bitsPerChannel 较大时，图片会出现明显噪点，建议默认 2。

图标处理：用户上传的图标需转换为 32×32 像素，并提取 RGBA 数据（使用 NSImage 的 bitmapRepresentation）。

加载器兼容性：加载器使用 DecompressionStream，需确保浏览器支持（Chrome/Edge）。

8. 后续扩展建议
支持多数据盘分片（拆分大应用）。

增加加密选项（AES-GCM）。

支持从命令行批量生成。

添加数据盘预览（提取元数据显示）。

📝 如何与 OpenCode + DeepSeek 协作
你可以将本文档直接粘贴到对话中，并告诉 AI：

“请根据这份开发文档，使用 Swift 和 SwiftUI 帮我实现一个 macOS 原生应用。请逐步生成完整的 Xcode 项目代码，包括所有界面和核心逻辑。”

AI 将根据文档逐步生成代码，你可以一次请求一个模块（如 UI 布局、数据编码、二维码生成等），最终整合成完整项目。

准备就绪。现在你可以开始与 OpenCode 对话，开发你的“数字软盘生成器”了！🚀

