import SwiftUI

struct MetadataFormView: View {
    @Binding var metadata: AppMetadata
    @State private var iconPreview: NSImage?
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("app_info"), systemImage: "info.circle")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    if let preview = iconPreview {
                        Image(nsImage: preview).resizable()
                            .frame(width: 48, height: 48).cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(Image(systemName: "app.badge").foregroundColor(.gray))
                    }
                    Button(L("choose_icon")) { selectIcon() }
                        .controlSize(.small)
                }

                VStack(spacing: 8) {
                    HStack {
                        Text(L("name")).frame(width: 50, alignment: .trailing)
                        TextField(L("name"), text: $metadata.name)
                    }
                    HStack {
                        Text(L("version")).frame(width: 50, alignment: .trailing)
                        TextField("1.0", text: $metadata.version)
                    }
                    HStack {
                        Text(L("developer")).frame(width: 50, alignment: .trailing)
                        TextField(L("developer"), text: $metadata.developer)
                    }
                }
            }
        }
    }

    private func selectIcon() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp]
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.begin { r in
            if r == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
                metadata.icon = img; metadata.iconData = ImageProcessor.processIcon(img)
                iconPreview = img
            }
        }
    }
}
