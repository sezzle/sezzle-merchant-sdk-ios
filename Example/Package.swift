// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SezzleCheckoutExample",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "SezzleCheckoutExample",
            dependencies: [
                .product(name: "SezzleMerchantSDK", package: "sezzle-merchant-sdk-ios")
            ],
            path: "SezzleCheckoutExample"
        )
    ]
)
