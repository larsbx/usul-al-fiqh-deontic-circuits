"""Replay PR-33's metadata-only outside-domain migration from pinned main suites.

Run once with ``python -m usul_corpus.migrate_pr33``. Idempotent on its own output;
fails on any other suite edit. Existing case notes supply the explanation, not a
new scholarly judgement. No ruling, holder, order, fact, class or evidence changes.
"""

from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path

from . import takhrij

# Exact bytes at main 57a3b1c, including PR #90's q160.f031 split.
SOURCES = {
    "sadi_furu.json": (1, "77416f91c9861af89ae974759ade551cec62894c774f14519438e902ed3c8c08", 36),
    "r2_sample1_lane_b.json": (2, "1b21e281eb6f369ad489574654977c7662aeaf09a3f06f45674ed56b81c91bda", 17),
}


def encode(data: dict, indent: int) -> bytes:
    return (json.dumps(data, ensure_ascii=False, indent=indent) + "\n").encode()


def migrate(data: dict, name: str) -> dict:
    indent, digest, count = SOURCES[name]
    original = deepcopy(data)
    for c in original["cases"]:
        for p in c.get("positions", []):
            if "outside" in p:
                if p["outside"] != c["note"] or takhrij.among(p["ruling"], takhrij.ENCODERS[c["encoder"]]["out"]):
                    raise ValueError(f"{name}: unexpected outside marker")
                del p["outside"]
    if sha256(encode(original, indent)).hexdigest() != digest:
        raise ValueError(f"{name}: migration input differs from pinned main 57a3b1c")
    added = 0
    for c in original["cases"]:
        for p in c.get("positions", []):
            if not takhrij.among(p["ruling"], takhrij.ENCODERS[c["encoder"]]["out"]):
                if not isinstance(p["ruling"], str) or not p["ruling"].strip():
                    raise ValueError(f"{name}: not a textual alternative")
                p["outside"] = c["note"]
                added += 1
    if added != count:
        raise ValueError(f"{name}: expected {count} alternatives, got {added}")
    return original


def main():
    root = Path(__file__).resolve().parents[2] / "corpus/takhrij"
    # Validate both inputs before writing either output.
    outputs = [(root / name, encode(migrate(json.loads((root / name).read_bytes()), name), indent))
               for name, (indent, _, _) in SOURCES.items()]
    for path, raw in outputs:
        path.write_bytes(raw)
        print(path.name)


if __name__ == "__main__":
    main()
