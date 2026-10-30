// swift-tools-version: 6.0
//
// The Apple side of the semantic search parity spike: the same bundle, run
// with ONNX Runtime and the swift-transformers tokenizer, checked against the
// bundle's golden set on macOS and in the iOS simulator.

import PackageDescription

let package = Package(
    name: "EmbeddingParity",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "EmbeddingParity", targets: ["EmbeddingParity"]),
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", exact: "1.24.2"),
        .package(url: "https://github.com/huggingface/swift-transformers", exact: "1.3.5"),
    ],
    targets: [
        .target(
            name: "EmbeddingParity",
            dependencies: [
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ]
        ),
        .testTarget(name: "EmbeddingParityTests", dependencies: ["EmbeddingParity"]),
    ]
)
