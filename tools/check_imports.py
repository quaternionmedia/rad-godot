#!/usr/bin/env python3
"""Every tracked `.import` sidecar has its imported artefact on disk.

`godot --headless --import` exits 0 whether or not it imported anything: one
importer refusing to run aborts the whole batch and the exit code does not
say so. A scene that references an asset then loads with the asset missing,
and the first thing to notice is whatever instantiates it. This asks the file
system what the importer said it would write.

    python tools/check_imports.py           # after an import; non-zero if anything is missing

It reads every `*.import` file git tracks, takes its `dest_files=[...]`, and
checks each path exists. A sidecar with no `dest_files` (some importers write
none) is reported as such and not counted as missing.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

DEST_FILES = re.compile(r'^dest_files=\[(.*)\]\s*$', re.MULTILINE)
QUOTED = re.compile(r'"([^"]*)"')


def tracked_sidecars() -> list[Path]:
    out = subprocess.run(
        ["git", "ls-files", "*.import"], capture_output=True, text=True, check=True
    ).stdout
    return [Path(line) for line in out.splitlines() if line.strip()]


def res_to_path(res: str) -> Path:
    return Path(res.removeprefix("res://"))


def main() -> int:
    sidecars = tracked_sidecars()
    if not sidecars:
        print("FAIL: git ls-files found no *.import files; is this the project root?", file=sys.stderr)
        return 1

    missing: list[tuple[Path, Path]] = []
    without_dest = 0
    checked = 0
    for sidecar in sidecars:
        if not sidecar.is_file():
            # Tracked and absent: a deletion nobody staged. Count it, do not crash.
            missing.append((sidecar, sidecar))
            continue
        text = sidecar.read_text(encoding="utf-8")
        m = DEST_FILES.search(text)
        if not m:
            without_dest += 1
            continue
        for dest in QUOTED.findall(m.group(1)):
            checked += 1
            if not res_to_path(dest).is_file():
                missing.append((sidecar, res_to_path(dest)))

    for sidecar, dest in missing:
        print(f"FAIL: {sidecar} says it imports to {dest}, which does not exist.", file=sys.stderr)
    if missing:
        print(f"\n{len(missing)} imported file(s) missing of {checked} declared. "
              "Run the import again and read its errors: one importer failing "
              "aborts the batch.", file=sys.stderr)
        return 1

    print(f"OK: {checked} imported file(s) present for {len(sidecars)} sidecars "
          f"({without_dest} declare no dest_files).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
