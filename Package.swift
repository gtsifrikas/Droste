// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "Droste",
                      platforms: [.iOS(.v9)],
                      products: [
                        // Products define the executables and libraries a package produces, and make them visible to other packages.
                        .library(name: "DrosteObjC", targets: ["DrosteObjC"]),
                        .library(name: "Droste",  targets: ["Droste"])
                        
                      ],
                      dependencies: [
                        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.1.2")),
                        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
                        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.2.0"))
                      ],
                      targets: [
                        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                        // Targets can depend on other targets in this package, and on products in packages this package depends on.
                        .target(name: "DrosteObjC",
                                path: "Sources/DrosteObjC"),
                        .target(name: "Droste",
                                dependencies: [
                                    .target(name: "DrosteObjC"),
                                    .product(name: "RxSwift", package: "RxSwift")
                                ],
                                path: "Sources/DrosteSwift",
                                linkerSettings: [.unsafeFlags(["-ObjC"])]),
                        .testTarget(name: "DrosteTests",
                                    dependencies: ["Droste",
                                                   .product(name: "RxTest", package: "RxSwift"),
                                                   "RxSwift",
                                                   "Nimble",
                                                   "Quick"],
                                    path: "Tests"),
                      ],
                      swiftLanguageVersions: [.v5]
)
