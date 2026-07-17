import Foundation
import AppKit

struct CLI {

    static func run() async {
        let args = Array(CommandLine.arguments.dropFirst())
        let parsed = parse(args)

        if parsed["help"] != nil || parsed["h"] != nil {
            print(helpText())
            return
        }

        guard let input = parsed["input"] ?? parsed["i"] else {
            print("❌ 请指定 --input 或 -i")
            print(helpText())
            return
        }
        let inputURL = URL(fileURLWithPath: (input as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            print("❌ 输入路径不存在: \(inputURL.path)")
            return
        }

        let outputDir: URL
        if let out = parsed["output"] ?? parsed["o"] {
            outputDir = URL(fileURLWithPath: (out as NSString).expandingTildeInPath)
            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        } else {
            outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        }

        let appName = parsed["name"] ?? parsed["n"] ?? "App"
        let version = parsed["version"] ?? parsed["v"] ?? "1.0"
        let developer = parsed["developer"] ?? parsed["d"] ?? ""
        let strict = parsed["strict"] != nil || parsed["s"] != nil

        // 1. Read HTML
        let html: String
        do {
            if inputURL.hasDirectoryPath {
                print("📁 扫描目录: \(inputURL.lastPathComponent)")
                html = try InlineBundler.bundle(directory: inputURL)
                print("   内联完成: \(html.utf8.count) 字节")
            } else {
                html = try String(contentsOf: inputURL, encoding: .utf8)
                print("📄 读取 HTML: \(html.utf8.count) 字节")
            }
        } catch {
            print("❌ 读取失败: \(error.localizedDescription)")
            return
        }

        // 2. Build metadata & process icon
        var meta = AppMetadata()
        meta.name = appName
        meta.version = version
        meta.developer = developer

        let iconImage: NSImage?
        if let iconPath = parsed["icon"] ?? parsed["c"] {
            let iconURL = URL(fileURLWithPath: (iconPath as NSString).expandingTildeInPath)
            if let image = NSImage(contentsOf: iconURL) {
                iconImage = image
                meta.iconData = ImageProcessor.processIcon(image)
                print("🖼️  图标: \(iconURL.lastPathComponent)")
            } else {
                print("⚠️  图标读取失败")
                iconImage = nil
            }
        } else {
            iconImage = nil
        }

        // 3. Build payload
        print("🔨 构建数据...")
        let appIdBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
        let appIdHex = appIdBytes.map { String(format: "%02x", $0) }.joined()

        guard let payload = DataPayloadBuilder.build(
            html: html, metadata: meta,
            appId: Data(appIdBytes), strict: strict
        ) else {
            print("❌ 数据载荷构建失败")
            return
        }

        // 4. Generate Floppy PNG
        print("🖼️  生成 Floppy PNG...")
        let pngData = PNGEncoder.createDataDisk(payload: payload, originalImage: iconImage)

        // 5. Generate QRboot
        print("📱 生成 QRboot...")
        let loaderHTML = LoaderHTMLTemplate.generate(appId: appIdHex, strict: strict)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~!*'();:@&=+$,/?%[]{}|")
        let encoded = loaderHTML.addingPercentEncoding(withAllowedCharacters: allowed) ?? loaderHTML
        let dataURI = "data:text/html;charset=UTF-8,\(encoded)"
        guard let qrPNG = QRCodeGenerator.pngData(from: dataURI) else {
            print("❌ QR 码生成失败")
            return
        }

        // 6. Write files
        let nameTag = appName.replacingOccurrences(of: "/", with: "_")
        let verTag = version.replacingOccurrences(of: "/", with: "_")
        let devTag = developer.replacingOccurrences(of: "/", with: "_")
        let base = "\(nameTag)_\(verTag)_\(devTag)_\(appIdHex.prefix(8))"

        let floppyURL = outputDir.appendingPathComponent("Floppy_\(base).png")
        let qrURL = outputDir.appendingPathComponent("QRboot_\(base).png")
        do {
            try qrPNG.write(to: qrURL)
            try pngData.write(to: floppyURL)
        } catch {
            print("❌ 写入失败: \(error.localizedDescription)")
            return
        }

        // 7. Stats
        let htmlSize = html.utf8.count
        let pngSize = pngData.count
        let qrSize = qrPNG.count
        let compressedSize = payload.count - (28 + 4132)

        print()
        print("✅ 生成成功!")
        print("   📄 HTML: \(formatBytes(htmlSize)) → \(formatBytes(compressedSize)) (zlib)")
        print("   🖼️  Floppy: \(formatBytes(pngSize))")
        print("   📱 QRboot: \(formatBytes(qrSize))")
        print("   📍 输出目录: \(outputDir.path)")
        print("   🔗 QRboot_\(base).png")
        print("   🔗 Floppy_\(base).png")
    }

    private static func parse(_ args: [String]) -> [String: String] {
        var dict = [String: String]()
        var i = 0
        while i < args.count {
            let arg = args[i]
            if arg.hasPrefix("--") {
                let key = String(arg.dropFirst(2))
                if i + 1 < args.count && !args[i+1].hasPrefix("-") {
                    dict[key] = args[i+1]
                    i += 2
                } else {
                    dict[key] = ""
                    i += 1
                }
            } else if arg.hasPrefix("-") && arg.count == 2 {
                let key = String(arg.dropFirst())
                if i + 1 < args.count && !args[i+1].hasPrefix("-") {
                    dict[key] = args[i+1]
                    i += 2
                } else {
                    dict[key] = ""
                    i += 1
                }
            } else {
                i += 1
            }
        }
        return dict
    }

    private static func helpText() -> String {
        """
        FloppyQR - 离线 Web 应用分发生成器

        用法:
          FloppyQR                              启动图形界面
          FloppyQR [选项]                       命令行生成

        选项:
          -i, --input <路径>       HTML 文件或项目目录（含 index.html）
          -o, --output <目录>      输出目录（默认当前目录）
          -n, --name <名称>        应用名称（必填）
          -v, --version <版本>     版本号（默认 1.0）
          -d, --developer <名称>   开发者
          -c, --icon <路径>        图标文件（PNG/JPEG）
          -s, --strict             启用 QRboot 与 Floppy ID 严格配对
          -h, --help               显示此帮助

        示例:
          FloppyQR -i ./myapp -n "MyApp" -d "Qingdaomy" -c ./icon.png
          FloppyQR --input ./index.html --name "游戏" --strict
        """
    }

    private static func formatBytes(_ b: Int) -> String {
        if b >= 1024*1024 { return String(format: "%.1f MB", Double(b)/1024/1024) }
        if b >= 1024 { return String(format: "%.1f KB", Double(b)/1024) }
        return "\(b) B"
    }
}
