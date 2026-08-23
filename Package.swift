// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BitwardenSdk",
    platforms: [
        .iOS(.v13),
        .macOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BitwardenSdk",
            targets: ["BitwardenSdk", "BitwardenFFI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BitwardenSdk",
            dependencies: ["BitwardenFFI", "BitwardenSdkSupport"],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]),
        .target(name: "BitwardenSdkSupport"),
        .binaryTarget(
            name: "BitwardenFFI",
            url: "https://github.com/KelaKing/sdk-swift/releases/download/macos-b57d1bb/BitwardenFFI.xcframework.zip",
            checksum: "af16b1c959b837831f2befee35ea8e0c7f5e61079ee3eab14c0a59d8b0513d8c"),
        .testTarget(
            name: "BitwardenSdkTests",
            dependencies: ["BitwardenSdk"])
    ],
    swiftLanguageModes: [.v5]
)
