#!/usr/bin/env python3
"""
TIOH (The Institute of Heraldry) award image monitor.

Periodically checks the TIOH website for new or updated award images and
reports changes so the app's assets can be refreshed. This is a stub
implementation — wire up the HTTP check and notification logic before
deploying to production.

Usage:
    python3 tools/monitor_tioh.py [--once]

Options:
    --once   Run a single check and exit (useful for CI).
"""

import argparse
import hashlib
import json
import os
import sys
import time
from datetime import datetime

CACHE_FILE = ".tioh_cache.json"
CHECK_INTERVAL_HOURS = 24

# Known TIOH gallery pages to monitor.
# Replace these with real TIOH URLs when they are stable.
TIOH_PAGES = [
    # "https://tioh.army.mil/Catalog/Heraldry.aspx?CategoryId=...",
]


def sha256_url(url: str) -> str:
    """Return SHA-256 of the content at url, or empty string on error."""
    try:
        import urllib.request
        with urllib.request.urlopen(url, timeout=15) as resp:
            return hashlib.sha256(resp.read()).hexdigest()
    except Exception as exc:
        print(f"  [warn] Could not fetch {url}: {exc}", file=sys.stderr)
        return ""


def load_cache(path: str) -> dict:
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def save_cache(path: str, data: dict):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def run_check(cache: dict) -> tuple[dict, list[str]]:
    """Check all pages; return updated cache and list of changed URLs."""
    changed = []
    for url in TIOH_PAGES:
        digest = sha256_url(url)
        if not digest:
            continue
        if cache.get(url) != digest:
            changed.append(url)
            cache[url] = digest
    return cache, changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true",
                        help="Run a single check and exit")
    args = parser.parse_args()

    if not TIOH_PAGES:
        print("No TIOH pages configured — add URLs to TIOH_PAGES and re-run.")
        return

    cache = load_cache(CACHE_FILE)

    while True:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{ts}] Checking {len(TIOH_PAGES)} TIOH page(s) …")
        cache, changed = run_check(cache)
        save_cache(CACHE_FILE, cache)

        if changed:
            print(f"  CHANGED ({len(changed)}):")
            for url in changed:
                print(f"    {url}")
            print("  Update AGSUBuilder/Assets.xcassets/ with fresh images.")
        else:
            print("  No changes detected.")

        if args.once:
            break

        next_check = CHECK_INTERVAL_HOURS * 3600
        print(f"  Next check in {CHECK_INTERVAL_HOURS} hour(s). Ctrl-C to stop.")
        time.sleep(next_check)


if __name__ == "__main__":
    main()
