// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorHttpServer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorHttpServer",
            targets: ["HttpServerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "HttpServerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/HttpServerPlugin"),
        .testTarget(
            name: "HttpServerPluginTests",
            dependencies: ["HttpServerPlugin"],
            path: "ios/Tests/HttpServerPluginTests")
    ]
)