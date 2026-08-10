#!/usr/bin/env python3
"""Scaffolds a standalone single-game Xcode project, reusing the shared
support files (MusicPlayer, GameCenter, Shared, GameplayMusic) and the given
game view file from the arcade app, unmodified.
"""
import os
import shutil
import sys

ROOT = "/Users/nasir/Documents/kids-games-90s"
SRC_APP = f"{ROOT}/KidsHappyClassicGames/KidsHappyClassicGames"
ICONS = f"{ROOT}/scripts/standalone_icons"

SHARED_FILES = ["MusicPlayer.swift", "GameCenter.swift", "Shared.swift", "GameplayMusic.m4a"]


def write(path, content):
    with open(path, "w") as f:
        f.write(content)


def scaffold(project_name, display_name, bundle_id, game_view_file, root_view_expr, icon_file):
    proj_dir = f"{ROOT}/{project_name}"
    app_dir = f"{proj_dir}/{project_name}"
    xcodeproj_dir = f"{proj_dir}/{project_name}.xcodeproj"
    assets_dir = f"{app_dir}/Assets.xcassets"

    os.makedirs(app_dir, exist_ok=True)
    os.makedirs(f"{xcodeproj_dir}/project.xcworkspace", exist_ok=True)
    os.makedirs(f"{xcodeproj_dir}/project.xcworkspace/xcshareddata/swiftpm/configuration", exist_ok=True)
    os.makedirs(f"{assets_dir}/AppIcon.appiconset", exist_ok=True)
    os.makedirs(f"{assets_dir}/AccentColor.colorset", exist_ok=True)

    # Copy shared support files + the game view, unmodified.
    for fname in SHARED_FILES:
        shutil.copy(f"{SRC_APP}/{fname}", f"{app_dir}/{fname}")
    shutil.copy(f"{SRC_APP}/{game_view_file}", f"{app_dir}/{game_view_file}")
    shutil.copy(f"{ICONS}/{icon_file}", f"{assets_dir}/AppIcon.appiconset/AppIcon-1024.png")

    # App entry point.
    write(f"{app_dir}/{project_name}App.swift", f"""import SwiftUI

@main
struct {project_name}App: App {{
    var body: some Scene {{
        WindowGroup {{
            {root_view_expr}
        }}
    }}
}}
""")

    # Asset catalog Contents.json files.
    write(f"{assets_dir}/Contents.json", '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')
    write(f"{assets_dir}/AccentColor.colorset/Contents.json",
          '{\n  "colors" : [\n    {\n      "idiom" : "universal"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')
    write(f"{assets_dir}/AppIcon.appiconset/Contents.json",
          '{\n  "images" : [\n    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024", "filename" : "AppIcon-1024.png" }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')

    # Workspace + swiftpm configuration.
    write(f"{xcodeproj_dir}/project.xcworkspace/contents.xcworkspacedata",
          '<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

    # project.pbxproj
    build_file_lines = []
    file_ref_lines = []
    group_lines = []
    sources_phase_lines = []
    resources_phase_lines = [f"\t\t\t\tAA0000010000008 /* Assets.xcassets in Resources */,"]

    # Fixed IDs for product + assets; sequential IDs for the rest.
    id_map = {}
    ordered_files = [f"{project_name}App.swift"] + [f for f in SHARED_FILES if f.endswith(".swift")] + [game_view_file, "Assets.xcassets", "GameplayMusic.m4a"]
    # de-dup while preserving order
    seen = set()
    files = []
    for f in ordered_files:
        if f not in seen:
            files.append(f)
            seen.add(f)

    for i, fname in enumerate(files, start=1):
        hexid = format(i, "X").zfill(1)
        build_id = f"AA0000010{hexid.zfill(6)}"
        ref_id = f"AA0001010{hexid.zfill(6)}"
        id_map[fname] = (build_id, ref_id)

    for fname in files:
        build_id, ref_id = id_map[fname]
        if fname == "Assets.xcassets":
            build_file_lines.append(f"\t\t{build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* Assets.xcassets */; }};")
            file_ref_lines.append(f"\t\t{ref_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
            resources_phase_lines = [f"\t\t\t\t{build_id} /* Assets.xcassets in Resources */,"]
        elif fname == "GameplayMusic.m4a":
            build_file_lines.append(f"\t\t{build_id} /* GameplayMusic.m4a in Resources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* GameplayMusic.m4a */; }};")
            file_ref_lines.append(f"\t\t{ref_id} /* GameplayMusic.m4a */ = {{isa = PBXFileReference; lastKnownFileType = file; path = GameplayMusic.m4a; sourceTree = \"<group>\"; }};")
            resources_phase_lines.append(f"\t\t\t\t{build_id} /* GameplayMusic.m4a in Resources */,")
        else:
            build_file_lines.append(f"\t\t{build_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* {fname} */; }};")
            file_ref_lines.append(f"\t\t{ref_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};")
            sources_phase_lines.append(f"\t\t\t\t{build_id} /* {fname} in Sources */,")
        group_lines.append(f"\t\t\t\t{ref_id} /* {fname} */,")

    product_ref_id = "AA0001010000000"

    pbxproj = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_file_lines)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{product_ref_id} /* {project_name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {project_name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{chr(10).join(file_ref_lines)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		AA00FAFB0000001 /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		AA00FAF70000001 /* {project_name} */ = {{
			isa = PBXGroup;
			children = (
{chr(10).join(group_lines)}
			);
			path = {project_name};
			sourceTree = "<group>";
		}};
		AA00FAF80000001 = {{
			isa = PBXGroup;
			children = (
				AA00FAF70000001 /* {project_name} */,
				AA00FAFA0000001 /* Products */,
			);
			sourceTree = "<group>";
		}};
		AA00FAFA0000001 /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref_id} /* {project_name}.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		AA00FAF60000001 /* {project_name} */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = AA00FAF50000001 /* Build configuration list for PBXNativeTarget "{project_name}" */;
			buildPhases = (
				AA00FAFB0000001 /* Frameworks */,
				AA00FAFC0000001 /* Sources */,
				AA00FAFD0000001 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = {project_name};
			productName = {project_name};
			productReference = {product_ref_id} /* {project_name}.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		AA00FAFE0000001 /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					AA00FAF60000001 = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = AA00FAF40000001 /* Build configuration list for PBXProject "{project_name}" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = AA00FAF80000001;
			productRefGroup = AA00FAFA0000001 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AA00FAF60000001 /* {project_name} */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		AA00FAFD0000001 /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(resources_phase_lines)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		AA00FAFC0000001 /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(sources_phase_lines)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		AA00FAF00000001 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 9KJNFQYHMS;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "{display_name}";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};
		AA00FAF10000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = 9KJNFQYHMS;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "{display_name}";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		AA00FAF20000001 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_CYCLES = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		AA00FAF30000001 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_CYCLES = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		AA00FAF40000001 /* Build configuration list for PBXProject "{project_name}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				AA00FAF30000001 /* Debug */,
				AA00FAF20000001 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		AA00FAF50000001 /* Build configuration list for PBXNativeTarget "{project_name}" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				AA00FAF10000001 /* Debug */,
				AA00FAF00000001 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = AA00FAFE0000001 /* Project object */;
}}
"""
    write(f"{xcodeproj_dir}/project.pbxproj", pbxproj)
    print(f"Scaffolded {project_name} at {proj_dir}")


if __name__ == "__main__":
    games = [
        dict(project_name="AppleMuncher", display_name="Apple Muncher",
             bundle_id="kids.happy.applemuncher", game_view_file="SnakeGameView.swift",
             root_view_expr="NavigationStack { SnakeGameView() }", icon_file="apple_muncher.png"),
        dict(project_name="PaddleBounce", display_name="Paddle Bounce",
             bundle_id="kids.happy.paddlebounce", game_view_file="PongView.swift",
             root_view_expr="NavigationStack { PongView() }", icon_file="paddle_bounce.png"),
        dict(project_name="BrickBlast", display_name="Brick Blast",
             bundle_id="kids.happy.brickblast", game_view_file="BreakoutView.swift",
             root_view_expr="NavigationStack { BreakoutView() }", icon_file="brick_blast.png"),
        dict(project_name="MoleBash", display_name="Mole Bash",
             bundle_id="kids.happy.molebash", game_view_file="WhackAMoleView.swift",
             root_view_expr="NavigationStack { WhackAMoleView() }", icon_file="mole_bash.png"),
        dict(project_name="MemoryMatch", display_name="Memory Match",
             bundle_id="kids.happy.memorymatch", game_view_file="MemoryMatchView.swift",
             root_view_expr="NavigationStack { MemoryMatchView() }", icon_file="memory_match.png"),
        dict(project_name="BeeBop", display_name="Bee Bop",
             bundle_id="kids.happy.beebop", game_view_file="BeeBopView.swift",
             root_view_expr="NavigationStack { BeeBopView() }", icon_file="bee_bop.png"),
    ]
    target = sys.argv[1] if len(sys.argv) > 1 else None
    for g in games:
        if target and g["project_name"] != target:
            continue
        scaffold(**g)
