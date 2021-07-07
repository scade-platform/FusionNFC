// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FusionNFC",
    platforms: [.macOS(.v10_14), .iOS(.v13)],
    products: [
        .library(
            name: "FusionNFC",
            targets: ["FusionNFC"]),
    ],
    dependencies: [
        .package(name: "Android", url: "https://github.com/scade-platform/swift-android.git", .branch("android/24"))        
    ],
    targets: [
        .target(
            name: "FusionNFC",
            dependencies: [
              .target(name: "FusionNFC_Common"),              
              .target(name: "FusionNFC_Apple", condition: .when(platforms: [.iOS, .macOS])),
              .target(name: "FusionNFC_Android", condition: .when(platforms: [.android])),
            ]            
        ),
        .target(
            name: "FusionNFC_Common"
        ),        
        .target(
            name: "FusionNFC_Apple",
            dependencies: [
              .target(name: "FusionNFC_Common"),
            ]                        
        ),            	
        .target(
            name: "FusionNFC_Android",
            dependencies: [
              .target(name: "FusionNFC_Common"),
              .product(name: "Android", package: "Android", condition: .when(platforms: [.android])),
              .product(name: "AndroidOS", package: "Android", condition: .when(platforms: [.android])),
              .product(name: "AndroidNFC", package: "Android", condition: .when(platforms: [.android]))              
            ],
            resources: [.copy("Generated/NFCReceiver.java")]         
        )
    ]
)

