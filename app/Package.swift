// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Herd",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Herd",
            targets: ["Herd"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Herd",
            path: "Sources/Herd"
        )
    ]
)
