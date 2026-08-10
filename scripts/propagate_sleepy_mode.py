#!/usr/bin/env python3
"""Propagates the Sleepy Mode feature (SleepyMode.swift + updated MusicPlayer.swift
and game view) from the arcade app into each of the 6 standalone single-game apps."""
import re
import shutil

ROOT = "/Users/nasir/Documents/kids-games-90s"
SRC_APP = f"{ROOT}/KidsHappyClassicGames/KidsHappyClassicGames"

APPS = [
    ("AppleMuncher", "SnakeGameView.swift"),
    ("PaddleBounce", "PongView.swift"),
    ("BrickBlast", "BreakoutView.swift"),
    ("MoleBash", "WhackAMoleView.swift"),
    ("MemoryMatch", "MemoryMatchView.swift"),
    ("BeeBop", "BeeBopView.swift"),
]

for project, game_view in APPS:
    proj_dir = f"{ROOT}/{project}"
    app_dir = f"{proj_dir}/{project}"
    pbxproj_path = f"{proj_dir}/{project}.xcodeproj/project.pbxproj"

    # Copy the updated shared files + the game view, unmodified.
    shutil.copy(f"{SRC_APP}/MusicPlayer.swift", f"{app_dir}/MusicPlayer.swift")
    shutil.copy(f"{SRC_APP}/SleepyMode.swift", f"{app_dir}/SleepyMode.swift")
    shutil.copy(f"{SRC_APP}/{game_view}", f"{app_dir}/{game_view}")

    with open(pbxproj_path) as f:
        content = f.read()

    # Find the next available sequential ID (one past the highest AA000101000000N).
    ids = [int(m, 16) for m in re.findall(r"AA000101000000([0-9A-F])", content)]
    next_id = max(ids) + 1
    hexid = format(next_id, "X")
    build_id = f"AA0000010000{'0' + hexid if len(hexid) == 2 else '00' + hexid}"
    ref_id = f"AA0001010000{'0' + hexid if len(hexid) == 2 else '00' + hexid}"
    # Simpler: reuse the same fixed-width scheme as the scaffold script.
    build_id = f"AA0000010{hexid.zfill(6)}"
    ref_id = f"AA0001010{hexid.zfill(6)}"

    content = content.replace(
        "/* End PBXBuildFile section */",
        f"\t\t{build_id} /* SleepyMode.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_id} /* SleepyMode.swift */; }};\n/* End PBXBuildFile section */",
    )
    content = content.replace(
        "/* End PBXFileReference section */",
        f"\t\t{ref_id} /* SleepyMode.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SleepyMode.swift; sourceTree = \"<group>\"; }};\n/* End PBXFileReference section */",
    )
    # Insert into the group's children list, right before the Assets.xcassets entry.
    content = re.sub(
        r"(\t\t\t\tAA0001010000006 /\* Assets\.xcassets \*/,\n)",
        f"\t\t{ref_id} /* SleepyMode.swift */,\n".replace("\t\t", "\t\t\t\t") + r"\1",
        content,
        count=1,
    )
    content = content.replace(
        "/* End PBXSourcesBuildPhase section */".replace("/* End", ""),  # no-op guard
        "/* End PBXSourcesBuildPhase section */",
    )
    content = re.sub(
        r"(\t\t\t\tAA0000010000005 /\* \w+\.swift in Sources \*/,\n)",
        r"\1" + f"\t\t\t\t{build_id} /* SleepyMode.swift in Sources */,\n",
        content,
        count=1,
    )

    with open(pbxproj_path, "w") as f:
        f.write(content)

    print(f"Updated {project}: build_id={build_id} ref_id={ref_id}")
