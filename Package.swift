// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WidgetFoundation",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WidgetFoundation",
            targets: ["WidgetFoundation"])
    ],
    targets: [
        .target(
            name: "WidgetFoundation"
        )
    ]
)
