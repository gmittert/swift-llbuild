// swift-tools-version:5.0

// This file defines Swift package manager support for llbuild. See:
//  https://github.com/apple/swift-package-manager/tree/master/Documentation

import PackageDescription

let package = Package(
    name: "llbuild",
    platforms: [
        .macOS(.v10_10), .iOS(.v9),
    ],
    products: [
        .library(
            name: "libllbuild",
            targets: ["libllbuild"]),
        .library(
            name: "llbuildSwift",
            targets: ["llbuildSwift"]),
        .library(
            name: "llbuildSwiftDynamic",
            type: .dynamic,
            targets: ["llbuildSwift"]),
    ],
    targets: [
        /// The llbuild testing tool.
        .target(
            name: "llbuild",
            dependencies: ["llbuildCommands"],
            path: "products/llbuild",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi", .when(platforms: [.windows])), .linkedLibrary("swiftCore")]
        ),

        /// The custom build tool used by the Swift package manager.
        .target(
            name: "swift-build-tool",
            dependencies: ["llbuildBuildSystem"],
            path: "products/swift-build-tool",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi"), .linkedLibrary("swiftCore")]
        ),

        /// The custom build tool used by the Swift package manager.
        .target(
            name: "llbuildSwift",
            dependencies: ["libllbuild"],
            path: "products/llbuildSwift",
            exclude: [],
            cxxSettings: [
              .define("libllbuild_EXPORTS", .when(platforms: [.windows])),
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),

        /// The public llbuild API.
        .target(
            name: "libllbuild",
            dependencies: ["llbuildCore", "llbuildBuildSystem"],
            path: "products/libllbuild",
            cxxSettings: [
              .define("libllbuild_EXPORTS", .when(platforms: [.windows])),
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),

        // MARK: Components
        
        .target(
            name: "llbuildBasic",
            dependencies: ["llvmSupport"],
            path: "lib/Basic",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),
        .target(
            name: "llbuildCore",
            dependencies: ["llbuildBasic"],
            path: "lib/Core",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .target(
            name: "llbuildBuildSystem",
            dependencies: ["llbuildCore"],
            path: "lib/BuildSystem",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),
        .target(
            name: "llbuildNinja",
            dependencies: ["llbuildBasic"],
            path: "lib/Ninja",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),
        .target(
            name: "llbuildCommands",
            dependencies: ["llbuildCore", "llbuildBuildSystem", "llbuildNinja"],
            path: "lib/Commands",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),

        // MARK: Test Targets

        .target(
            name: "llbuildBasicTests",
            dependencies: ["llbuildBasic", "gtest"],
            path: "unittests/Basic",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
              .unsafeFlags(["-Wno-modules-import-nested-redundant"]),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi", .when(platforms: [.windows])), .linkedLibrary("swiftCore")]
        ),
        .target(
            name: "llbuildCoreTests",
            dependencies: ["llbuildCore", "gtest"],
            path: "unittests/Core",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
              .unsafeFlags(["-Wno-modules-import-nested-redundant"]),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi", .when(platforms: [.windows])), .linkedLibrary("swiftCore")]
        ),

        .target(
            name: "llbuildBuildSystemTests",
            dependencies: ["llbuildBuildSystem", "gtest"],
            path: "unittests/BuildSystem",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
              .unsafeFlags(["-Wno-modules-import-nested-redundant"]),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi", .when(platforms: [.windows])), .linkedLibrary("swiftCore")]
        ),

        .target(
            name: "llbuildNinjaTests",
            dependencies: ["llbuildNinja", "gtest"],
            path: "unittests/Ninja",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
              .unsafeFlags(["-Wno-modules-import-nested-redundant"]),
            ],
            linkerSettings: [.linkedLibrary("Shlwapi", .when(platforms: [.windows])), .linkedLibrary("swiftCore")]
        ),

        .testTarget(
            name: "llbuildSwiftTests",
            dependencies: ["llbuildSwift"],
            path: "unittests/Swift",
            cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
              .unsafeFlags(["-Wno-modules-import-nested-redundant"]),
            ]
        ),
        
        // MARK: GoogleTest

        .target(
            name: "gtest",
            path: "utils/unittest/googletest/src",
            exclude: [
                "gtest-death-test.cc",
                "gtest-filepath.cc",
                "gtest-port.cc",
                "gtest-printers.cc",
                "gtest-test-part.cc",
                "gtest-typed-test.cc",
                "gtest.cc",
            ],
            cxxSettings: [
                .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
                .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]
        ),
        
        // MARK: Ingested LLVM code.
        .target(
          name: "llvmDemangle",
          path: "lib/llvm/Demangle",
          cxxSettings: [
              .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
              .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
              .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
          ]
        ),

        .target(
            name: "llvmSupport",
            dependencies: ["llvmDemangle"],
            path: "lib/llvm/Support",
            cxxSettings: [
                .define("LLVM_ON_WIN32", .when(platforms: [.windows])),
                .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
                .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ],
            linkerSettings: [.linkedLibrary("ncurses", .when(platforms: [.linux, .macOS]))]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
