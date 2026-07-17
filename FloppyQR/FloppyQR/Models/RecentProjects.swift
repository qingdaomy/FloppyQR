import Foundation

struct RecentProject: Codable, Identifiable {
    let id: String
    let name: String
    let htmlPreview: String
    let date: Date
    let appIdHex: String
    let htmlFull: String
}

struct RecentProjectsManager {
    private static let key = "RecentProjects"
    private static let maxCount = 10

    static func load() -> [RecentProject] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let projects = try? JSONDecoder().decode([RecentProject].self, from: data) else {
            return []
        }
        return projects.sorted { $0.date > $1.date }
    }

    static func save(name: String, html: String, appIdHex: String) {
        var projects = load()
        let preview = String(html.prefix(200))
        let truncated = html.count > 50000 ? String(html.prefix(50000)) : html
        let project = RecentProject(
            id: appIdHex,
            name: name.isEmpty ? "未命名" : name,
            htmlPreview: preview,
            date: Date(),
            appIdHex: appIdHex,
            htmlFull: truncated
        )
        projects.removeAll { $0.id == appIdHex }
        projects.insert(project, at: 0)
        if projects.count > maxCount { projects = Array(projects.prefix(maxCount)) }
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
