// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "qrshot",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "qrshot", targets: ["qrshot"])
    ],
    targets: [
        .target(name: "QRShotKit"),
        .executableTarget(name: "qrshot", dependencies: ["QRShotKit"]),
        .testTarget(name: "QRShotKitTests", dependencies: ["QRShotKit"]),
    ]
)
