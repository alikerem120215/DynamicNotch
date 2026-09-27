// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DynamicNotch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DynamicNotch",
            targets: ["DynamicNotch"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DynamicNotch",
            dependencies: [],
            path: "Sources/DynamicNotch",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
