// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to
// build this package.
//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0


import PackageDescription

let package = Package(
// snippet-start:[glue.swift.basics.package.attributes]
    name: "basics",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
// snippet-end:[glue.swift.basics.package.attributes]
// snippet-start:[glue.swift.basics.package.dependencies]
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/awslabs/aws-sdk-swift",
            from: "0.10.0"
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            branch: "main"
        ),
        .package(
            name: "SwiftUtilities",
            path: "../../../modules/SwiftUtilities"
        ),
    ],
// snippet-end:[glue.swift.basics.package.dependencies]
// snippet-start:[glue.swift.basics.package.targets]
    targets: [
        // A target defines a module or a test suite. A target can depend on
        // other targets in this package. They can also depend on products in
        // other packages that this package depends on.
// snippet-start:[glue.swift.basics.package.target.executable]
        .executableTarget(
            name: "basics",
            dependencies: [
//                .product(name: "AWSGlue", package: "aws-sdk-swift"),
//                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ServiceManager",
                "SwiftUtilities"
            ],
            path: "./Sources"
        ),
// snippet-end:[glue.swift.basics.package.target.executable]
// snippet-start:[glue.swift.basics.package.target.manager]
        .target(
            name: "ServiceManager",
            dependencies: [
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                .product(name: "AWSGlue", package: "aws-sdk-swift")
            ],
            path: "./ServiceManager"
        ),
// snippet-end:[glue.swift.basics.package.target.manager]
// snippet-start:[glue.swift.basics.package.target.tests]
        .testTarget(
            name: "basics-tests",
            dependencies: [
                .product(name: "AWSGlue", package: "aws-sdk-swift"),
                .product(name: "AWSS3", package: "aws-sdk-swift"),
                "basics",
                "SwiftUtilities"
            ],
            path: "./Tests"
        )
// snippet-end:[glue.swift.basics.package.target.tests]
    ]
// snippet-end:[glue.swift.basics.package.targets]
)
