"""What every check under tools/ needs and none should carry twice.

Each check is a script: it prints one `OK:` line on success, one `FAIL:` line
per finding on failure, and its exit status is the verdict. `tools/dev.ps1`
reads only the exit status, so a check that prints FAIL and exits 0 is a check
that never fires -- `fail()` and `ok()` keep the two together.

Every path is relative to the repository root, whatever directory the check
was launched from: `dev.ps1` sets the location, a hand run may not.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def tracked(pattern: str) -> list[Path]:
    """Files git tracks matching a pathspec, as paths relative to ROOT.

    Tracked and not the working tree: a file created but never added is not
    part of what a clone receives, and every check here is about the clone.
    """
    out = subprocess.run(
        ["git", "ls-files", pattern], capture_output=True, text=True, check=True, cwd=ROOT
    ).stdout
    return [Path(line) for line in out.splitlines() if line.strip()]


def sha256_of(path: Path) -> str:
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def read_json(path: Path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)


def ok(message: str) -> None:
    print(f"OK: {message}")


def verdict(failures: int, success: str) -> int:
    """Exit status from a failure count; prints the success line only when it is one."""
    if failures:
        return 1
    ok(success)
    return 0
