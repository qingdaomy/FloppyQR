import SwiftUI
import AppKit

struct ContentView: View {
    @State private var config = GenerationConfig()
    @State private var status: GenerationStatus = .idle
    @State private var qrPreview: NSImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("数字软盘生成器")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                CodeInputView(htmlCode: $config.htmlCode)

                MetadataFormView(metadata: $config.metadata)

                AdvancedOptionsView(options: $config.advanced)

                HStack(spacing: 16) {
                    Button("生成并保存...") { generateAndSave() }
                        .buttonStyle(.borderedProminent)
                        .disabled(status == .generating || !config.metadata.isValid || config.htmlCode.isEmpty)

                    if let qr = qrPreview {
                        Image(nsImage: qr)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 80, height: 80)
                            .cornerRadius(4)
                    }
                }

                statusView
            }
            .padding(20)
        }
        .frame(minWidth: 680, minHeight: 560)
    }

    @ViewBuilder
    private var statusView: some View {
        HStack {
            switch status {
            case .idle:
                Text("状态: 准备就绪").foregroundColor(.secondary)
            case .generating:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在生成...")
                }
            case .success:
                Label("生成成功", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .error(let msg):
                Label(msg, systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.callout)
    }

    private func generateAndSave() {
        guard config.metadata.isValid, !config.htmlCode.isEmpty else { return }
        status = .generating
        qrPreview = nil

        let htmlCode = config.htmlCode
        let metadata = config.metadata
        let strictPairing = config.advanced.strictPairing
        let appName = config.metadata.name

        Task.detached {
            do {
                let appIdBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
                let appIdHex = appIdBytes.map { String(format: "%02x", $0) }.joined()

                let iconData = metadata.iconData ?? ImageProcessor.placeholderIcon()
                var meta = metadata
                meta.iconData = iconData

                guard let payload = DataPayloadBuilder.build(
                    html: htmlCode,
                    metadata: meta,
                    appId: Data(appIdBytes),
                    strict: strictPairing
                ) else {
                    await updateStatus(.error("数据载荷构建失败"))
                    return
                }

                let pngData = PNGEncoder.createDataDisk(payload: payload)
                let loaderHTML = LoaderHTMLTemplate.generate(appId: appIdHex, strict: strictPairing)

                let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~!*'();:@&=+$,/?%#[]{}|")
                let encoded = loaderHTML.addingPercentEncoding(withAllowedCharacters: allowed) ?? loaderHTML
                let dataURI = "data:text/html;charset=UTF-8,\(encoded)"

                guard let qrPNG = QRCodeGenerator.pngData(from: dataURI),
                      let qrImage = QRCodeGenerator.generate(from: dataURI) else {
                    await updateStatus(.error("二维码生成失败"))
                    return
                }

                await MainActor.run {
                    self.qrPreview = qrImage
                }

                try await performSave(
                    pngData: pngData,
                    qrPNG: qrPNG,
                    appIdHex: appIdHex,
                    appName: appName
                )

                await updateStatus(.success)
            } catch {
                await updateStatus(.error("错误: \(error.localizedDescription)"))
            }
        }
    }

    @MainActor
    private func performSave(
        pngData: Data,
        qrPNG: Data,
        appIdHex: String,
        appName: String
    ) async throws {
        let sanitizedName = appName.replacingOccurrences(of: "/", with: "_")
        let prefix = sanitizedName.isEmpty ? String(appIdHex.prefix(8)) : sanitizedName
        let baseName = "\(prefix)_\(appIdHex.prefix(8))"

        let panel = NSOpenPanel()
        panel.title = "选择保存目录"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = "将保存启动头二维码和数据盘到所选目录"

        guard panel.runModal() == .OK, let dir = panel.url else {
            updateStatus(.idle)
            return
        }

        let qrURL = dir.appendingPathComponent("boot_\(baseName).png")
        let dataURL = dir.appendingPathComponent("datadisk_\(baseName).png")

        try qrPNG.write(to: qrURL)
        try pngData.write(to: dataURL)
    }

    @MainActor
    private func updateStatus(_ newStatus: GenerationStatus) {
        status = newStatus
    }
}
