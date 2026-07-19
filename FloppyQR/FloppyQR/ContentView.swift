import SwiftUI
import AppKit

struct ContentView: View {
    @State private var config = GenerationConfig()
    @State private var status: GenerationStatus = .idle
    @State private var qrPreview: NSImage?
    @State private var genStats: (htmlSize: Int, compressedSize: Int, pngSize: Int)?
    @StateObject private var lang = LanguageManager.shared
    private var isGenerating: Bool { if case .generating = status { return true }; return false }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("FloppyQR").font(.largeTitle).fontWeight(.bold)
                        Spacer()
                        Picker("", selection: $lang.current) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }

                    CodeInputView(htmlCode: $config.htmlCode, isBundling: $config.isBundling)

                    MetadataFormView(metadata: $config.metadata)

                    AdvancedOptionsView(options: $config.advanced)
                }
                .padding(20)
            }

            Divider()
            HStack {
                statusView
                Spacer()
                HStack(spacing: 16) {
                    if let qr = qrPreview {
                        Image(nsImage: qr).resizable().interpolation(.none)
                            .frame(width: 80, height: 80).cornerRadius(4)
                    }
                    Button(L("generate")) { generateAndSave() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating || !config.metadata.isValid || config.htmlCode.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 680, minHeight: 560)
    }

    @ViewBuilder
    private var statusView: some View {
        HStack {
            switch status {
            case .idle:
                Text(L("ready")).foregroundColor(.secondary)
            case .generating(let step):
                HStack(spacing: 8) { ProgressView().scaleEffect(0.8); Text(step) }
            case .success:
                Label(L("success"), systemImage: "checkmark.circle.fill").foregroundColor(.green)
            case .error(let msg):
                Label("\(L("error")): \(msg)", systemImage: "xmark.circle.fill").foregroundColor(.red)
            }
        }
        .font(.callout)

        if let s = genStats {
            Text("HTML: \(formatBytes(s.htmlSize)) → \(formatBytes(s.compressedSize)) (zlib) | PNG: \(formatBytes(s.pngSize))")
                .font(.caption).foregroundColor(.secondary).padding(.top, 4)
        }
    }

    private func generateAndSave() {
        guard config.metadata.isValid, !config.htmlCode.isEmpty else { return }
        status = .generating(L("prepare"))
        qrPreview = nil; genStats = nil

        let htmlCode = config.htmlCode; let metadata = config.metadata
        let strictPairing = config.advanced.strictPairing; let appName = config.metadata.name

        Task.detached {
            do {
                let appIdBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
                let appIdHex = appIdBytes.map { String(format: "%02x", $0) }.joined()

                let iconData = metadata.iconData ?? ImageProcessor.placeholderIcon()
                var meta = metadata; meta.iconData = iconData

                await updateStatus(.generating(L("build_data")))
                guard let payload = DataPayloadBuilder.build(html: htmlCode, metadata: meta, appId: Data(appIdBytes), strict: strictPairing) else {
                    await updateStatus(.error("\(L("error")): build failed")); return
                }
                let htmlSize = htmlCode.utf8.count
                let compressedSize = payload.count - (28 + 4132)

                await updateStatus(.generating(L("gen_png")))
                let floppyQRHTML = FloppyQRHTMLTemplate.generate(appId: appIdHex, strict: strictPairing)
                let zLDRData = CompressionService.compress(floppyQRHTML.data(using: .utf8)!)
                let pngData = PNGEncoder.createDataDisk(payload: payload, originalImage: metadata.icon, zLDR: zLDRData)

                await updateStatus(.generating(L("gen_qr")))
                let loaderHTML = LoaderHTMLTemplate.generate(appId: appIdHex, strict: strictPairing)
                let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~!$&'()*+,;=/:?@{}[]`")
                let encoded = loaderHTML.addingPercentEncoding(withAllowedCharacters: allowed) ?? loaderHTML
                let dataURI = "data:text/html,\(encoded)"

                guard let qrPNG = QRCodeGenerator.pngData(from: dataURI),
                      let qrImage = QRCodeGenerator.generate(from: dataURI) else {
                    await updateStatus(.error("\(L("error")): QR generation")); return
                }

                await MainActor.run { self.qrPreview = qrImage }

                let version = metadata.version; let developer = metadata.developer
                try await performSave(pngData: pngData, qrPNG: qrPNG, appIdHex: appIdHex, appName: appName, version: version, developer: developer)

                let totalPNG = pngData.count + qrPNG.count
                await MainActor.run {
                    self.genStats = (htmlSize, compressedSize, totalPNG)
                    RecentProjectsManager.save(name: appName, html: htmlCode, appIdHex: appIdHex)
                }
                await updateStatus(.success)
            } catch {
                await updateStatus(.error("\(L("error")): \(error.localizedDescription)"))
            }
        }
    }

    @MainActor
    private func performSave(pngData: Data, qrPNG: Data, appIdHex: String, appName: String, version: String, developer: String) async throws {
        let name = appName.replacingOccurrences(of: "/", with: "_")
        let ver = version.replacingOccurrences(of: "/", with: "_")
        let dev = developer.replacingOccurrences(of: "/", with: "_")
        let tag = name.isEmpty ? "" : "\(name)_"
        let base = "\(tag)\(ver)_\(dev)_\(appIdHex.prefix(8))"

        let panel = NSOpenPanel()
        panel.title = L("save_title")
        panel.prompt = L("save")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.message = L("save_msg")

        guard panel.runModal() == .OK, let dir = panel.url else { updateStatus(.idle); return }

        try qrPNG.write(to: dir.appendingPathComponent("QRboot_\(base).png"))
        try pngData.write(to: dir.appendingPathComponent("Floppy_\(base).png"))
    }

    @MainActor
    private func updateStatus(_ s: GenerationStatus) { status = s }

    private func formatBytes(_ b: Int) -> String {
        if b >= 1024*1024 { return String(format: "%.1f MB", Double(b)/1024/1024) }
        if b >= 1024 { return String(format: "%.1f KB", Double(b)/1024) }
        return "\(b) B"
    }
}
