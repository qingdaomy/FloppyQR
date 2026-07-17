import SwiftUI

struct CodeInputView: View {
    @Binding var htmlCode: String
    @Binding var isBundling: Bool
    @State private var showHistory = false
    @State private var projects: [RecentProject] = []
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(L("html_code"), systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                Button(L("open_file")) { openFile() }
                    .controlSize(.small)
                Button(L("choose_dir")) { openDirectory() }
                    .controlSize(.small)
                    .disabled(isBundling)
                Button(L("clear")) { htmlCode = "" }
                    .controlSize(.small)

                Text("  ").font(.caption).foregroundColor(.secondary)

                if !projects.isEmpty {
                    Button(L("history")) { showHistory.toggle() }
                        .controlSize(.small)
                        .popover(isPresented: $showHistory) {
                            VStack(spacing: 0) {
                                ForEach(projects) { p in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(p.name).font(.caption).fontWeight(.semibold)
                                            Text(p.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption2).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture { htmlCode = p.htmlFull; showHistory = false }
                                    .contextMenu { Button(L("delete"), role: .destructive) { deleteProject(p) } }
                                    Divider()
                                }
                            }
                            .frame(width: 220)
                            .padding(.vertical, 4)
                        }
                }
            }

            TextEditor(text: $htmlCode)
                .font(.system(.body, design: .monospaced))
                .frame(height: 360)
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(4)
                .overlay(isBundling ? ProgressView(L("bundling")) : nil)
        }
        .onAppear { projects = RecentProjectsManager.load() }
    }

    private func deleteProject(_ p: RecentProject) {
        var list = RecentProjectsManager.load()
        list.removeAll { $0.id == p.id }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "RecentProjects")
        }
        projects = list
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.html]
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.begin { r in
            if r == .OK, let url = panel.url, let c = try? String(contentsOf: url, encoding: .utf8) { htmlCode = c }
        }
    }

    private func openDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true; panel.canCreateDirectories = false
        panel.message = L("select_dir")
        panel.begin { r in
            guard r == .OK, let url = panel.url else { return }
            isBundling = true
            DispatchQueue.global().async {
                do {
                    let b = try InlineBundler.bundle(directory: url)
                    DispatchQueue.main.async { htmlCode = b; isBundling = false }
                } catch { DispatchQueue.main.async { isBundling = false } }
            }
        }
    }
}
