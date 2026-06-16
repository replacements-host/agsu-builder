#!/usr/bin/env python3
"""
Generate placeholder PNG assets for every imageAsset reference in the JSON data files,
plus the four coat base images. Run from the repository root:

    python3 tools/generate_placeholders.py

The script creates properly-structured Xcode asset catalog imagesets under
AGSUBuilder/Assets.xcassets/. Replace the generated PNGs with real artwork before
submitting to the App Store.
"""

import json
import os
import re
import struct
import zlib

ASSETS_DIR = "AGSUBuilder/Assets.xcassets"
DATA_DIR = "AGSUBuilder/Data"

# ── Color palette by category ──────────────────────────────────────────────
CATEGORY_COLORS = {
    "Ribbons":       (139,  0,   0),   # dark red
    "Badges/Group1": (184, 147,  58),  # gold
    "Badges/Group2": ( 27,  94, 158),  # blue
    "Badges/Group3": ( 45, 106,  79),  # green
    "Badges/Group4": (107,  61, 138),  # purple
    "Badges/Group5": (193, 122,  42),  # amber
    "Badges/ID":     ( 74,  85, 104),  # slate
    "Tabs":          ( 85, 107,  47),  # olive
    "Branch":        (  0,  51, 102),  # army blue
    "Rank/Enlisted": (107, 142,  35),  # olive drab
    "Rank/Officer":  (184, 147,  58),  # gold
    "Coat":          (100, 100, 100),  # gray
}

# ── Pixel sizes per category ───────────────────────────────────────────────
CATEGORY_SIZES = {
    "Ribbons":       (100, 35),
    "Badges/Group1": ( 80, 80),
    "Badges/Group2": ( 80, 80),
    "Badges/Group3": ( 80, 80),
    "Badges/Group4": ( 80, 80),
    "Badges/Group5": ( 80, 80),
    "Badges/ID":     ( 60, 80),
    "Tabs":          (120, 30),
    "Branch":        ( 60, 60),
    "Rank/Enlisted": ( 60, 60),
    "Rank/Officer":  ( 60, 60),
    "Coat":          (300, 420),
}

# ── Coat base images (no imageAsset key in JSON — referenced directly) ─────
COAT_ASSETS = [
    "Coat/fig14_1_officer_male",
    "Coat/fig14_2_officer_female",
    "Coat/fig14_3_enlisted_male",
    "Coat/fig14_4_enlisted_female",
]


# ── PNG helpers ────────────────────────────────────────────────────────────

def _png_chunk(name: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(name + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", crc)


def make_png(width: int, height: int, r: int, g: int, b: int) -> bytes:
    """Return bytes for a solid-colour RGB PNG."""
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = _png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    raw_row = b"\x00" + bytes([r, g, b] * width)
    idat = _png_chunk(b"IDAT", zlib.compress(raw_row * height))
    iend = _png_chunk(b"IEND", b"")
    return sig + ihdr + idat + iend


# ── Category helpers ───────────────────────────────────────────────────────

def category_of(asset_path: str) -> str:
    parts = asset_path.split("/")
    if parts[0] == "Badges" and len(parts) >= 3:
        return f"Badges/{parts[1]}"
    if parts[0] == "Rank" and len(parts) >= 3:
        return f"Rank/{parts[1]}"
    return parts[0]


def color_of(category: str):
    return CATEGORY_COLORS.get(category, (100, 100, 100))


def size_of(category: str):
    return CATEGORY_SIZES.get(category, (60, 60))


# ── Asset catalog helpers ──────────────────────────────────────────────────

def ensure_group_contents(group_path: str):
    """Write a bare Contents.json into a group folder if missing."""
    full = os.path.join(ASSETS_DIR, group_path)
    os.makedirs(full, exist_ok=True)
    cpath = os.path.join(full, "Contents.json")
    if not os.path.exists(cpath):
        with open(cpath, "w") as f:
            json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)


def create_imageset(asset_path: str):
    """Create <asset_path>.imageset/ with a PNG and Contents.json."""
    parts = asset_path.split("/")
    filename = parts[-1] + ".png"
    cat = category_of(asset_path)
    color = color_of(cat)
    w, h = size_of(cat)

    imageset_dir = os.path.join(ASSETS_DIR, asset_path + ".imageset")
    os.makedirs(imageset_dir, exist_ok=True)

    png_path = os.path.join(imageset_dir, filename)
    if not os.path.exists(png_path):
        with open(png_path, "wb") as f:
            f.write(make_png(w, h, *color))

    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

    return imageset_dir


# ── Main ───────────────────────────────────────────────────────────────────

def collect_asset_paths():
    paths = set()
    for fname in os.listdir(DATA_DIR):
        if not fname.endswith(".json"):
            continue
        with open(os.path.join(DATA_DIR, fname)) as f:
            content = f.read()
        paths.update(re.findall(r'"imageAsset"\s*:\s*"([^"]+)"', content))
    return sorted(paths)


def main():
    # Change to repo root so relative paths resolve correctly
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    os.chdir(repo_root)

    asset_paths = collect_asset_paths()
    all_paths = asset_paths + COAT_ASSETS

    print(f"Generating {len(all_paths)} placeholder imagesets …")

    # Ensure every intermediate group directory has a Contents.json
    groups: set[str] = set()
    for ap in all_paths:
        parts = ap.split("/")
        for i in range(1, len(parts)):
            groups.add("/".join(parts[:i]))
    for g in sorted(groups):
        ensure_group_contents(g)

    for ap in all_paths:
        d = create_imageset(ap)
        print(f"  {d}")

    print(f"\nDone — {len(all_paths)} imagesets written.")
    print("Replace generated PNGs with real artwork before App Store submission.")


if __name__ == "__main__":
    main()
