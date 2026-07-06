// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TKUIKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "TKUIKit",
            targets: ["TKUIKit"]
        ),
        .library(
            name: "TKUIKitDynamic",
            type: .dynamic,
            targets: ["TKUIKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: "4.6.0"),
        .package(path: "../TKLogging"),
    ],
    targets: [
        .target(
            name: "TKUIKit",
            dependencies: [
                .product(name: "SnapKit-Dynamic", package: "SnapKit"),
                .byName(name: "Kingfisher"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "TKLogging", package: "TKLogging"),
            ],
            path: "TKUIKit/Sources/TKUIKit",
            resources: [
                .process("Resources/Fonts"),
                .copy("Resources/Lottie"),
            ],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: "TKUIKitTests",
            dependencies: ["TKUIKit"],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
