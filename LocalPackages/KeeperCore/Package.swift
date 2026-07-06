// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "KeeperCore",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(name: "KeeperCore", targets: ["KeeperCore"]),
    ],
    dependencies: [
        .package(path: "../TKLocalize"),
        .package(path: "../TKKeychain"),
        .package(path: "../Ledger"),
        .package(path: "../TKLogging"),
        .package(path: "../TronSwift"),
        .package(path: "../TKFeatureFlags"),
        .package(url: "https://github.com/ton-org/kit-ios.git", exact: "1.0.0"),
        .package(url: "https://github.com/tonkeeper/CryptoSwift", revision: "1d31a1ffb6043655f3faba9d160db67b2e547e49"),
        .package(url: "https://github.com/tonkeeper/PunycodeSwift", revision: "30a462bdb4398ea835a3585472229e0d74b36ba5"),
        .package(url: "https://github.com/tonkeeper/ton-swift", exact: "1.0.36"),
        .package(url: "https://github.com/tonkeeper/URKit", .upToNextMinor(from: "16.0.0")),
        .package(url: "https://github.com/tonkeeper/ton-api-swift", exact: "0.7.3"),
        .package(url: "https://github.com/tonkeeper/battery-api-swift", .upToNextMinor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-openapi-runtime", .upToNextMinor(from: "0.3.0")),
    ],
    targets: [
        .target(
            name: "KeeperCoreComponents",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "TKKeychain", package: "TKKeychain"),
                .product(name: "TKLogging", package: "TKLogging"),
            ],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: "KeeperCoreComponentsTests",
            dependencies: [
                "KeeperCoreComponents",
            ],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "KeeperCoreSensitive",
            dependencies: [
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TKLogging", package: "TKLogging"),
                .target(name: "KeeperCoreComponents"),
            ],
            path: "Sources/KeeperCoreSensitive",
            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "KeeperCore",
            dependencies: [
                .product(name: "URKit", package: "URKit"),
                .product(name: "TKLocalize", package: "TKLocalize"),
                .product(name: "TKKeychain", package: "TKKeychain"),
                .product(name: "TonTransport", package: "Ledger"),
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "TonAPI", package: "ton-api-swift"),
                .product(name: "TKBatteryAPI", package: "battery-api-swift"),
                .product(name: "TonStreamingAPI", package: "ton-api-swift"),
                .product(name: "TonStreamingAPIV2", package: "ton-api-swift"),
                .product(name: "TronSwift", package: "TronSwift"),
                .product(name: "TronSwiftAPI", package: "TronSwift"),
                .product(name: "TKFeatureFlags", package: "TKFeatureFlags"),
                .product(name: "Punycode", package: "PunycodeSwift"),
                .target(name: "TonConnectAPI"),
                .target(name: "SwapAPI"),
                .target(name: "MultichainAPI"),
                .target(name: "TKTradingAPI"),
                .target(name: "KeeperCoreComponents"),
                .product(name: "TKLogging", package: "TKLogging"),
                .product(name: "TONWalletKit", package: "kit-ios"),
                .target(name: "KeeperCoreSensitive"),
            ],
            path: "Sources/KeeperCore",
            resources: [
                .copy("PackageResources/DefaultBootConfiguration.json"),
                .copy("PackageResources/known_accounts.json"),
            ]
        ),
        .testTarget(
            name: "KeeperCoreTests",
            dependencies: [
                "KeeperCore",
                "KeeperCoreComponents",
                "KeeperCoreSensitive",
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "TonConnectAPI",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
            ],
            path: "Packages/TonConnectAPI",
            sources: ["Sources"],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "SwapAPI",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
            ],
            path: "Packages/SwapAPI",
            sources: ["Sources"],
            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "MultichainAPI",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
            ],
            path: "Packages/MultichainAPI",
            sources: ["Sources"],
            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .target(
            name: "TKTradingAPI",
            dependencies: [
                .product(
                    name: "OpenAPIRuntime",
                    package: "swift-openapi-runtime"
                ),
            ],
            path: "Packages/TKTradingAPI",
            sources: ["Sources"],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
        .testTarget(
            name: "WalletCoreTests",
            dependencies: [
                "KeeperCore",
            ],

            swiftSettings: [
                .treatAllWarnings(as: .error),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
