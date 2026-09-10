// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FoldawayCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FoldawayCore", targets: ["FoldawayCore"])],
    targets: [
        .target(name: "FoldawayCore"),
        .testTarget(name: "FoldawayCoreTests", dependencies: ["FoldawayCore"]),
    ]
)
