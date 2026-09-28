// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LifeInWeeksTests",
    platforms: [.macOS(.v14)],
    targets: [
        .testTarget(
            name: "CoreLogicTests",
            path: "Tests"
        )
    ]
)
