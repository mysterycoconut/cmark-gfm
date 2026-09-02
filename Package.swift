// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "cmark-gfm",
    products: [
        .library(name: "cmark-gfm", targets: ["cmark-gfm"]),
    ],
    targets: [
        .target(
            name: "cmark-gfm",
            path: ".",
            exclude: [
                "src/scanners.re",
                "src/libcmark-gfm.pc.in",
                "src/config.h.in",
                "src/cmark-gfm_version.h.in",
                "src/CMakeLists.txt",
                "src/main.c",
                "src/entities.inc",
                "src/case_fold_switch.inc",
                "extensions/CMakeLists.txt",
                "extensions/ext_scanners.re",
            ],
            sources: ["src", "extensions"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("src"),
                .headerSearchPath("extensions"),
            ]
        ),
    ]
)
