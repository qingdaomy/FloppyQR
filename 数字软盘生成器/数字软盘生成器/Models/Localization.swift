import Foundation

enum Language: String, CaseIterable, Identifiable {
    case zh = "中文"
    case en = "English"
    case fr = "Français"
    case es = "Español"
    var id: String { rawValue }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var current: Language {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "AppLanguage") }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "AppLanguage") ?? "中文"
        current = Language(rawValue: raw) ?? .zh
    }

    func str(_ key: String) -> String {
        translations[current]?[key] ?? translations[.zh]?[key] ?? key
    }

    private let translations: [Language: [String: String]] = [
        .zh: [
            "html_code": "HTML 代码",
            "open_file": "打开文件",
            "choose_dir": "选择目录",
            "clear": "清空",
            "history": "历史",
            "generate": "生成并保存...",
            "app_info": "应用信息",
            "name": "名称",
            "version": "版本",
            "developer": "开发者",
            "choose_icon": "选择图标",
            "advanced": "高级选项",
            "strict_pair": "QRboot 与 Floppy ID 匹配",
            "ready": "就绪",
            "prepare": "准备中",
            "build_data": "构建数据",
            "gen_png": "生成 PNG",
            "gen_qr": "生成二维码",
            "success": "生成成功",
            "error": "错误",
            "save_title": "选择保存目录",
            "save_msg": "将保存 QRboot 和 Floppy 文件",
            "save": "保存",
            "recent": "最近项目",
            "load": "加载",
            "delete": "删除",
            "bundling": "打包中…",
            "select_dir": "选择包含 index.html 的项目目录",
        ],
        .en: [
            "html_code": "HTML Code",
            "open_file": "Open File",
            "choose_dir": "Choose Folder",
            "clear": "Clear",
            "history": "History",
            "generate": "Generate & Save...",
            "app_info": "App Info",
            "name": "Name",
            "version": "Version",
            "developer": "Developer",
            "choose_icon": "Choose Icon",
            "advanced": "Advanced",
            "strict_pair": "QRboot ↔ Floppy ID Match",
            "ready": "Ready",
            "prepare": "Preparing",
            "build_data": "Building data",
            "gen_png": "Generating PNG",
            "gen_qr": "Generating QR",
            "success": "Success",
            "error": "Error",
            "save_title": "Choose save directory",
            "save_msg": "Will save QRboot and Floppy files",
            "save": "Save",
            "recent": "Recent",
            "load": "Load",
            "delete": "Delete",
            "bundling": "Bundling…",
            "select_dir": "Select folder containing index.html",
        ],
        .fr: [
            "html_code": "Code HTML",
            "open_file": "Ouvrir",
            "choose_dir": "Dossier",
            "clear": "Effacer",
            "history": "Historique",
            "generate": "Générer...",
            "app_info": "Infos App",
            "name": "Nom",
            "version": "Version",
            "developer": "Développeur",
            "choose_icon": "Icône",
            "advanced": "Avancé",
            "strict_pair": "Correspondance ID QRboot↔Floppy",
            "ready": "Prêt",
            "success": "Succès",
            "error": "Erreur",
            "save_title": "Choisir dossier",
            "save_msg": "Sauvegardera QRboot et Floppy",
            "save": "Sauvegarder",
            "recent": "Récent",
            "load": "Charger",
            "delete": "Supprimer",
            "bundling": "Assemblage…",
            "select_dir": "Dossier avec index.html",
        ],
        .es: [
            "html_code": "Código HTML",
            "open_file": "Abrir",
            "choose_dir": "Carpeta",
            "clear": "Limpiar",
            "history": "Historial",
            "generate": "Generar...",
            "app_info": "Información",
            "name": "Nombre",
            "version": "Versión",
            "developer": "Desarrollador",
            "choose_icon": "Icono",
            "advanced": "Avanzado",
            "strict_pair": "Coincidencia ID QRboot↔Floppy",
            "ready": "Listo",
            "success": "Éxito",
            "error": "Error",
            "save_title": "Elegir carpeta",
            "save_msg": "Guardará QRboot y Floppy",
            "save": "Guardar",
            "recent": "Reciente",
            "load": "Cargar",
            "delete": "Eliminar",
            "bundling": "Empaquetando…",
            "select_dir": "Carpeta con index.html",
        ],
    ]
}

func L(_ key: String) -> String {
    LanguageManager.shared.str(key)
}
