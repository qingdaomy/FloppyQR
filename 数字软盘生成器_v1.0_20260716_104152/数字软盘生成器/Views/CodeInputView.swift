import SwiftUI

struct CodeInputView: View {
    @Binding var htmlCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("HTML 代码", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                Button("打开文件") { openFile() }
                    .controlSize(.small)
                Button("清空") { htmlCode = "" }
                    .controlSize(.small)
            }

            TextEditor(text: $htmlCode)
                .font(.system(.body, design: .monospaced))
                .frame(height: 360)
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(4)
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
}
