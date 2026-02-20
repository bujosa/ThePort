// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "GRDB": .framework
    ]
)
#endif

let package = Package(
    name: "ThePort",
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0")
    ]
)
