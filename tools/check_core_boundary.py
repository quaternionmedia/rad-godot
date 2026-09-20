#!/usr/bin/env python3
"""`addons/rad/core/*.gd` touches no scene, input, display, OS or loader API.

rad's contract requires state machine and geometry in a platform-free core,
"enforced by a grep lint in CI" -- no DOM on the web, no `android.*` on
Android. This is the Godot reading: the core may not reach the scene tree,
read input, ask the display server, call the OS or load a resource. It is a
set of pure functions over dictionaries, and a port author can read it
without knowing Godot.

    python tools/check_core_boundary.py     # non-zero with the offending lines

Comments are stripped before matching, so prose may name what code may not.
"""

from __future__ import annotations

import re

from repo import ROOT, fail, tracked, verdict

FORBIDDEN = re.compile(
    r"\b(Node|Input|Viewport|DisplayServer|SceneTree|get_tree|get_node|OS|Engine)\b"
    r"|\$[A-Za-z_]"
    r"|\b(pre)?load\("
)
COMMENT = re.compile(r"#.*$")


def main() -> int:
    scripts = tracked("addons/rad/core/*.gd")
    if not scripts:
        fail("git ls-files found no addons/rad/core/*.gd; is the core in the tree?")
        return 1
    findings = 0
    for script in scripts:
        for lineno, line in enumerate((ROOT / script).read_text(encoding="utf-8").splitlines(), 1):
            code = COMMENT.sub("", line)
            m = FORBIDDEN.search(code)
            if m:
                findings += 1
                fail(f"{script}:{lineno}: `{m.group(0)}` -- {line.strip()}")
    return verdict(findings, f"{len(scripts)} core scripts reference no scene, input, display, OS or loader API.")


if __name__ == "__main__":
    raise SystemExit(main())
