import SwiftUI

struct AppMetadata {
    var name: String = ""
    var version: String = "1.0"
    var developer: String = ""
    var icon: NSImage?
    var iconData: Data?

    var isValid: Bool {
        !name.isEmpty && icon != nil
    }
}

struct AdvancedOptions {
    var strictPairing: Bool = false
}

struct GenerationConfig {
    var htmlCode: String = ""
    var metadata: AppMetadata = AppMetadata()
    var advanced: AdvancedOptions = AdvancedOptions()
    var isBundling: Bool = false
}

enum GenerationStatus: Equatable {
    case idle
    case generating(String)
    case success
    case error(String)
}
