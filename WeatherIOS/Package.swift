// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WeatherIOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherIOS",
            targets: ["WeatherIOS"]
        )
    ],
    targets: [
        .target(
            name: "WeatherIOS",
            path: "WeatherIOS",
            exclude: [
                "WeatherApp.swift",
                "Info.plist"
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Fonts")
            ]
        ),
        .testTarget(
            name: "WeatherIOSTests",
            dependencies: ["WeatherIOS"],
            path: "WeatherIOSTests"
        )
    ]
)
