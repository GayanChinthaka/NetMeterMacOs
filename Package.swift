// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetMeter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "NetMeter",
            targets: ["NetMeter"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NetMeter",
            path: "Sources/NetMeter"
        )
    ]
)
