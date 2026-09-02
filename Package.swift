// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "cmark-gfm",
    products: [
        .library(name: "cmark-gfm", targets: ["cmark-gfm"]),
        .library(name: "cmark-gfm-extensions", targets: ["cmark-gfm-extensions"]),
    ],
    targets: [
        .target(
            name: "cmark-gfm",
            path: "src",
            exclude: [
                "scanners.re",
                "libcmark-gfm.pc.in",
                "config.h.in",
                "CMakeLists.txt",
                "main.c",
            ]
        ),
        .target(
            name: "cmark-gfm-extensions",
            dependencies: ["cmark-gfm"],
            path: "extensions",
            exclude: [
                "CMakeLists.txt",
                "ext_scanners.re",
            ],
            cSettings: [
                .headerSearchPath("../src"),
            ]
        ),
    ]
)
