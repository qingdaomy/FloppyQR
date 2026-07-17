import SwiftUI

struct CodeInputView: View {
    @Binding var htmlCode: String
    @State private var isBundling = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("HTML 代码", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                Button("打开文件") { openFile() }
                    .controlSize(.small)
                Button("选择目录") { openDirectory() }
                    .controlSize(.small)
                    .disabled(isBundling)
                Button("清空") { htmlCode = "" }
                    .controlSize(.small)
            }

            TextEditor(text: $htmlCode)
                .font(.system(.body, design: .monospaced))
                .frame(height: 360)
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(4)
                .overlay(
                    isBundling ? ProgressView("打包中…") : nil
                )
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.html]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK, let url = panel.url,
               let content = try? String(contentsOf: url, encoding: .utf8) {
                htmlCode = content
            }
        }
    }

    private func openDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.message = "选择包含 index.html 的项目目录"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            isBundling = true
            DispatchQueue.global().async {
                do {
                    let bundled = try InlineBundler.bundle(directory: url)
                    DispatchQueue.main.async {
                        htmlCode = bundled
                        isBundling = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        isBundling = false
                    }
                }
            }
        }
    }
}
