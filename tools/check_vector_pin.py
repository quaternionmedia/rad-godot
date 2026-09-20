#!/usr/bin/env python3
"""`conformance/vectors.json` is the copy `conformance/vectors.lock` says it is.

The vectors are rad's governed artefact and this repository holds a copy. A
copy drifts silently: an upstream amendment, a hand edit to make a red case
green, a line-ending conversion -- each leaves a file that still parses and a
suite that still runs, against a contract nobody agreed to. The lock records
the rad commit the copy was taken from and the SHA-256 of its bytes; this
recomputes the hash and refuses a mismatch. Upgrading the pin is a reviewed
change to both files together, never a side effect of anything else.

    python tools/check_vector_pin.py      # non-zero when the copy is not the pinned bytes

Prints the vector version and the hash prefix a release claim quotes:
"conformant to vectors <version> at <sha256[0..12]>".
"""

from __future__ import annotations

from pathlib import Path

from repo import fail, read_json, sha256_of, verdict

VECTORS = Path("conformance/vectors.json")
LOCK = Path("conformance/vectors.lock")


def main() -> int:
    lock = read_json(LOCK)
    actual = sha256_of(VECTORS)
    if actual != lock["sha256"]:
        fail(f"{VECTORS} hashes to {actual[:12]}..., the lock pins {lock['sha256'][:12]}... "
             f"(rad {lock['rad_ref'][:7]}). Restore the file or update the lock in the same change.")
        return verdict(1, "")
    version = read_json(VECTORS)["version"]
    return verdict(0, f"vectors {version} at {actual[:12]} match the lock (rad {lock['rad_ref'][:7]}).")


if __name__ == "__main__":
    raise SystemExit(main())
