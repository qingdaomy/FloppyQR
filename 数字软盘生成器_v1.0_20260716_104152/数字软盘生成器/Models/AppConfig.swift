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
    var strictPairing: Bool = true
    var bitsPerChannel: Int = 2
    var loaderURL: String = "https://YOUR_USERNAME.github.io/floppy-loader/"

    var bitsRange: ClosedRange<Int> { 1...4 }
}

struct GenerationConfig {
    var htmlCode: String = ""
    var metadata: AppMetadata = AppMetadata()
    var advanced: AdvancedOptions = AdvancedOptions()
}

struct GeneratedOutput {
    var bootQR: NSImage
    var dataDiskPNG: Data
    var appId: String
}

enum GenerationStatus: Equatable {
    case idle
    case generating
    case success
    case error(String)
}
