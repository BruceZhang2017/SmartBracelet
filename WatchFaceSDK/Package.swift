// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WatchFaceSDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "WatchFaceSDK",
            targets: ["WatchFaceSDK"]
        )
    ],
    dependencies: [
        // 注意: 二进制依赖需要在 Xcode 项目中手动添加
        // - WatchProtocolSDK.xcframework
        // - ABParTool.xcframework
    ],
    targets: [
        .target(
            name: "WatchFaceSDK",
            dependencies: [],
            path: "WatchFaceSDK",
            exclude: [],
            sources: [
                "Core/",
                "Models/",
                "Transfer/",
                "Extensions/",
                "Protocols/",
                "WatchFaceSDK.swift"
            ]
        )
    ]
)
