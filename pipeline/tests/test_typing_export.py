"""Every encoder is typed (formal/lean/Usul/Typing). The check is on the Prolog export the Lean kernel
generates (examples/v41_types.pl): each encoder of the registry has a type there, reading as many
fields as it has facts. A new encoder must be typed over its qāʿida's type before it lands."""

import re
from pathlib import Path

from usul_corpus import takhrij

ROOT = Path(__file__).resolve().parents[2]
EXPORT = (ROOT / "examples/v41_types.pl").read_text(encoding="utf-8")


def test_every_encoder_is_typed_with_its_arity():
    typed = set(re.findall(r"^encoder_type\((\w+),", EXPORT, re.M))
    reads = {}
    for e, _, f in re.findall(r"^encoder_reads\((\w+), (\d+), (\w+)\)\.", EXPORT, re.M):
        reads.setdefault(e, []).append(f)
    assert typed == set(takhrij.ENCODERS)
    assert {e: len(fs) for e, fs in reads.items()} == {n: len(e["facts"]) for n, e in takhrij.ENCODERS.items()}
