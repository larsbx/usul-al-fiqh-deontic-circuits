#!/usr/bin/env python3
"""Translate ground fatwa fixture data to Lean, never evaluate a query.

The committed Prolog data is the frozen migration input. Its original corpus
JSON provenance remains in its header; the existing corpus generator owns that
translation. This translator accepts only the explicit data vocabulary below,
preserves declaration order and expectations, and rejects unsupported syntax.
Run with --check to verify byte-for-byte reproducibility.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
INPUTS = [
    "examples/v40_fatwa_cases.pl",
    "examples/v40_fatwa_oracle_fixtures.pl",
]
OUTPUT = ROOT / "formal/lean/UsulTest/Fixtures/Fatwa.lean"
DIRECTIVES = {
    "v40_fatwa_cases.pl": {
        ":- encoding(utf8).",
        ":- multifile(encoder/2).",
        ":- multifile(fact/3).",
        ":- multifile(fixture_expectation/3).",
        ":- discontiguous(encoder/2).",
        ":- discontiguous(encoder_fact/3).",
        ":- discontiguous(fact/3).",
        ":- discontiguous(text_ruling/2).",
        ":- discontiguous(position/2).",
        ":- discontiguous(fixture_expectation/3).",
        ":- discontiguous(fixture_premise/2).",
    },
    "v40_fatwa_oracle_fixtures.pl": {
        ":- encoding(utf8).",
        ":- ensure_loaded(v40_fatwa_rules).",
        ":- ensure_loaded(v40_fatwa_cases).",
        ":- multifile([encoder/2, fact/3, fixture_expectation/3]).",
        ":- discontiguous([encoder/2, fact/3, fixture_expectation/3]).",
    },
}

# Keep the anonymous query variable distinct from the quoted ground atom '_'.
WILDCARD = object()


class Parser:
    def __init__(self, text: str):
        self.tokens = re.findall(r"'(?:\\.|[^'\\])*'|[A-Za-z_][A-Za-z_0-9]*|[(),.]|\S", text)
        self.at = 0

    def take(self, wanted: str | None = None) -> str:
        token = self.tokens[self.at]
        self.at += 1
        if wanted is not None and token != wanted:
            raise ValueError(f"expected {wanted!r}, got {token!r}")
        return token

    def term(self):
        token = self.take()
        if token.startswith("'"):
            if re.search(r"\\(?!['\\])", token[1:-1]):
                raise ValueError(f"unsupported quoted-atom escape: {token!r}")
            atom = token[1:-1].replace("\\'", "'").replace("\\\\", "\\")
        elif re.fullmatch(r"[a-z][A-Za-z_0-9]*", token):
            atom = token
        elif token == "_":
            atom = WILDCARD
        else:
            raise ValueError(f"unsupported atom: {token!r}")
        if self.at < len(self.tokens) and self.tokens[self.at] == "(":
            if atom is WILDCARD:
                raise ValueError("a variable cannot be a compound functor")
            self.take("(")
            args = [self.term()]
            while self.tokens[self.at] == ",":
                self.take(",")
                args.append(self.term())
            self.take(")")
            return atom, args
        return atom


def terms(path: Path):
    # The source vocabulary contains metadata directives only. Never silently
    # discard an initialization, a new import, or another executable directive.
    body_lines = []
    seen_directives = set()
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("%"):
            continue
        if stripped.startswith(":-"):
            if stripped not in DIRECTIVES[path.name] or stripped in seen_directives:
                raise ValueError(f"unsupported or duplicate directive in {path.name}: {stripped}")
            seen_directives.add(stripped)
            continue
        body_lines.append(line)
    if seen_directives != DIRECTIVES[path.name]:
        raise ValueError(f"missing expected directives in {path.name}")
    body = "\n".join(body_lines)
    parser = Parser(body)
    while parser.at < len(parser.tokens):
        term = parser.term()
        parser.take(".")
        yield term


def canonical(term) -> str:
    if isinstance(term, tuple):
        return canonical(term[0]) + "(" + ",".join(map(canonical, term[1])) + ")"
    if not isinstance(term, str):
        raise ValueError("fixture names must be ground")
    if re.fullmatch(r"[a-z][A-Za-z_0-9]*", term):
        return term
    return "'" + term.replace("\\", "\\\\").replace("'", "\\'") + "'"


def string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def optional(value) -> str:
    return "none" if value is WILDCARD else "(some " + string(value) + ")"


def query(term) -> str:
    if not isinstance(term, tuple) or term[0] != "query" or len(term[1]) != 1:
        raise ValueError(f"invalid query wrapper: {term!r}")
    if not isinstance(term[1][0], tuple):
        raise ValueError("query must be a predicate application")
    name, args = term[1][0]
    arities = {"bank": 2, "oracle": 3, "agrees": 1, "within_positions": 1, "text_ruling": 2}
    if name not in arities or len(args) != arities[name] or not all(isinstance(a, str) or a is WILDCARD for a in args):
        raise ValueError(f"unsupported query: {term!r}")
    if args[0] is WILDCARD:
        raise ValueError("case identifier must be ground")
    if name == "bank":
        if args[1] is WILDCARD:
            raise ValueError("bank expectation must be ground")
        return f".bank {string(args[0])} {string(args[1])}"
    if name == "oracle":
        return f".oracle {string(args[0])} {optional(args[1])} {optional(args[2])}"
    if name == "text_ruling":
        return f".textRuling {string(args[0])} {optional(args[1])}"
    method = {"agrees": "agrees", "within_positions": "withinPositions"}[name]
    return f".{method} {string(args[0])}"


def generate() -> str:
    cases: dict[str, dict] = {}
    expectations = []
    premises: dict[str, list[str]] = {}
    for source in INPUTS:
        for term in terms(ROOT / source):
            if not isinstance(term, tuple):
                raise ValueError("data declaration must be a predicate application")
            name, args = term
            arities = {"encoder": 2, "encoder_fact": 3, "fact": 3,
                       "position": 2, "text_ruling": 2, "fixture_expectation": 3,
                       "fixture_premise": 2}
            if name not in arities or len(args) != arities[name]:
                raise ValueError(f"unsupported data predicate or arity: {name}")
            if name not in ("fixture_expectation", "fixture_premise") and not all(isinstance(a, str) for a in args):
                raise ValueError(f"data arguments must be ground atoms: {name}")
            if name == "encoder":
                case_id, encoder = args
                if case_id in cases:
                    raise ValueError(f"duplicate encoder: {case_id}")
                cases[case_id] = {"encoder": encoder, "encoderFacts": [], "facts": [], "positions": [], "textRuling": None}
            elif name in ("encoder_fact", "fact"):
                case_id, key, value = args
                target = cases[case_id]["encoderFacts" if name == "encoder_fact" else "facts"]
                if any(k == key for k, _ in target):
                    raise ValueError(f"duplicate fact key: {case_id}/{key}")
                target.append((key, value))
            elif name == "position":
                case_id, value = args
                cases[case_id]["positions"].append(value)
            elif name == "text_ruling":
                case_id, value = args
                if cases[case_id]["textRuling"] is not None:
                    raise ValueError(f"duplicate text ruling: {case_id}")
                cases[case_id]["textRuling"] = value
            elif name == "fixture_expectation":
                fixture_name, goal, expected = args
                if expected not in ("expect_true", "expect_false"):
                    raise ValueError(f"unsupported expectation: {expected}")
                expectations.append((canonical(fixture_name), query(goal), expected == "expect_true"))
            elif name == "fixture_premise":
                fixture_name, goal = args
                premises.setdefault(canonical(fixture_name), []).append(query(goal))
            else:
                raise ValueError(f"unsupported data predicate: {name}")
    names = [row[0] for row in expectations]
    if len(set(names)) != len(names) or set(premises) - set(names):
        raise ValueError("duplicate expectation name or orphan premise")
    if len(expectations) != 300 or sum(not row[2] for row in expectations) != 3 or sum(map(len, premises.values())) != 6:
        raise ValueError("frozen v40 fatwa manifest changed; review and update migration contract")
    lines = [
        "-- Generated by formal/fixtures/gen_fatwa_fixtures.py; do not edit.",
        "-- Strict data translation only: no query answers are computed here.",
    ]
    for source in INPUTS:
        digest = hashlib.sha256((ROOT / source).read_bytes()).hexdigest()
        lines.append(f"-- Source SHA-256 {source}: {digest}")
    lines += [
        "import Usul.Fixtures.Fatwa", "import Usul.Fixtures.Runner", "",
        "namespace UsulTest.Fixtures.Fatwa", "", "open Usul.Fixtures Usul.Fixtures.Fatwa", "",
        "set_option maxRecDepth 4096", "", "def cases : List Case := [",
    ]
    for index, (case_id, data) in enumerate(cases.items()):
        lines.append(f"  {{ id := {string(case_id)}, encoder := {string(data['encoder'])}")
        for key in ("encoderFacts", "facts"):
            entries = ", ".join(f"({string(k)}, {string(v)})" for k, v in data[key])
            lines.append(f"    {key} := [{entries}]")
        text_ruling = data["textRuling"]
        if text_ruling is not None:
            lines.append(f"    textRuling := some {string(text_ruling)}")
        if data["positions"]:
            lines.append("    positions := [" + ", ".join(map(string, data["positions"])) + "]")
        lines.append("  }" + ("," if index < len(cases) - 1 else ""))
    lines += ["]", "", "private def vector (name : String) (expected : Bool) (q : Query)",
              "    (premises : List Query := []) : Fixture :=", "  ⟨name, expected, evaluate cases q, premises.map (evaluate cases)⟩", "",
              "def fixtures : List Fixture := ["]
    for index, (name, goal, expected) in enumerate(expectations):
        premise_args = ""
        if name in premises:
            premise_args = " [" + ", ".join(premises[name]) + "]"
        lines.append(f"  vector {string(name)} {str(expected).lower()} ({goal}){premise_args}" + ("," if index < len(expectations) - 1 else ""))
    lines += ["]", "", "end UsulTest.Fixtures.Fatwa", ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    generated = generate()
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text() != generated:
            print(f"stale generated fixture data: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
        print("fatwa Lean fixture data is current (300 expectations, 6 premises)")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(generated)
        print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
