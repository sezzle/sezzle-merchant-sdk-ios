// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SezzleMerchantSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SezzleMerchantSDK",
            targets: ["SezzleMerchantSDK"]
        )
    ],
    targets: [
        .target(
            name: "SezzleMerchantSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SezzleMerchantSDKTests",
            dependencies: ["SezzleMerchantSDK"]
        )
    ]
)
