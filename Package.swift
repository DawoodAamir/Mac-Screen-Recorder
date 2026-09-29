// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "RecorderCore", products: [.library(name: "RecorderCore", targets: ["RecorderCore"])],
    targets: [
        .target(name: "RecorderCore", path: "Sources/Core"),
        .testTarget(name: "RecorderCoreTests", dependencies: ["RecorderCore"], path: "Tests"),
    ])
