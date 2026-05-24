// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoverStudio",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CoverStudio", targets: ["CoverStudio"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "CoverStudio",
            dependencies: ["Yams"],
            path: "Sources/CoverStudio",
            resources: [.copy("Resources")]
        ),
    ]
)
