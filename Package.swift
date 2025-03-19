// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ObservableStorage",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ObservableStorage",
            targets: ["ObservableStorage"]
        ),
        .executable(
            name: "ObservableStorageClient",
            targets: ["ObservableStorageClient"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/jmccloud827/KeychainManager.git", from: "1.0.0-latest")
    ],
    targets: [
        .macro(
            name: "ObservableStorageMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "KeychainManager", package: "KeychainManager")
            ]
        ),
        .target(name: "ObservableStorage", dependencies: [
            "ObservableStorageMacros",
            .product(name: "KeychainManager", package: "KeychainManager")
        ]),
        .executableTarget(name: "ObservableStorageClient", dependencies: ["ObservableStorage"])
    ]
)
