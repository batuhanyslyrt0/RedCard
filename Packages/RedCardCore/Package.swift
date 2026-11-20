// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RedCardCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "RedCardCore", targets: ["RedCardCore"])
    ],
    targets: [
        .target(name: "RedCardCore"),
        // Writes the rules as JSON for publishing:  swift run export-rules
        .executableTarget(name: "export-rules", dependencies: ["RedCardCore"]),
        .testTarget(name: "RedCardCoreTests", dependencies: ["RedCardCore"])
    ]
)
