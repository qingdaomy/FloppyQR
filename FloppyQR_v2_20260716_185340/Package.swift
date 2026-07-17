// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "FloppyDiskGenerator",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "FloppyDiskGenerator",
            path: "数字软盘生成器",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library", "-framework", "AppKit", "-framework", "SwiftUI", "-framework", "CoreImage", "-framework", "Compression"])
            ]
        )
    ]
)
