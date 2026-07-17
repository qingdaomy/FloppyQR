import SwiftUI

struct MetadataFormView: View {
    @Binding var metadata: AppMetadata
    @State private var iconPreview: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("应用信息", systemImage: "info.circle")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    if let preview = iconPreview {
                        Image(nsImage: preview)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(Image(systemName: "app.badge").foregroundColor(.gray))
                    }
                    Button("选择图标") { selectIcon() }
                        .controlSize(.small)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text("名称:").frame(width: 50, alignment: .trailing)
                        TextField("应用名称", text: $metadata.name)
                    }
                    HStack {
                        Text("版本:").frame(width: 50, alignment: .trailing)
                        TextField("1.0", text: $metadata.version)
                    }
                    HStack {
                        Text("开发者:").frame(width: 50, alignment: .trailing)
                        TextField("开发者名称", text: $metadata.developer)
                    }
                }
            }
        }
    }

    private func selectIcon() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.begin { response in
            if response == .OK, let url = panel.url,
               let image = NSImage(contentsOf: url) {
                metadata.icon = image
                metadata.iconData = ImageProcessor.processIcon(image)
                iconPreview = image
            }
        }
    }
}
