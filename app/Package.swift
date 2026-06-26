// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FeelsIOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeelsCore",
            targets: ["FeelsCore"]
        )
    ],
    targets: [
        .target(
            name: "FeelsCore",
            path: "FeelsCore"
        ),
        .testTarget(
            name: "FeelsIOSTests",
            dependencies: ["FeelsCore"],
            path: "FeelsIOSTests"
        )
    ]
)
