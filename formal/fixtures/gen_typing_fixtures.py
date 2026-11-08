#!/usr/bin/env python3
"""Translate the complete v41 typing fact export to Lean data; never execute Prolog.

The source export is independently checked against Lean by check-type-export.sh.
This parser accepts only the seven ground declaration predicates and the three
known file directives. Unexpected syntax, duplicates, dangling names, and read
index gaps are errors. Fixture queries are evaluated in Lean, not translated to
answers here.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "examples/v41_types.pl"
FIXTURES = ROOT / "examples/v41_typing_fixtures.pl"
OUTPUT = ROOT / "formal/lean/Usul/Fixtures/TypingData.lean"
ATOM = re.compile(r"[a-z][A-Za-z0-9_]*\Z")
ARITIES = {"qaida_type": 2, "type_extends": 2, "type_field": 3,
           "type_value": 2, "encoder_type": 2, "encoder_reads": 3, "implies": 3}
DIRECTIVES = {":- encoding(utf8).",
              ":- discontiguous([qaida_type/2, type_extends/2, type_field/3, encoder_type/2, encoder_reads/3, implies/3, type_value/2]).",
              ":- multifile([encoder_reads/3, type_field/3])."}


def split_args(text: str) -> list[str]:
    result, start, depth, quoted, escape = [], 0, 0, False, False
    for i, char in enumerate(text):
        if escape:
            escape = False
        elif quoted and char == "\\":
            escape = True
        elif char == "'":
            quoted = not quoted
        elif not quoted:
            if char == "[":
                depth += 1
            elif char == "]":
                depth -= 1
                if depth < 0:
                    raise ValueError(f"Unbalanced list: {text}")
            elif char == "," and depth == 0:
                result.append(text[start:i].strip())
                start = i + 1
    if quoted or escape or depth:
        raise ValueError(f"Unbalanced ground term: {text}")
    result.append(text[start:].strip())
    return result


def atom(text: str) -> str:
    if ATOM.fullmatch(text):
        return text
    if len(text) >= 2 and text[0] == text[-1] == "'":
        body = text[1:-1]
        if re.search(r"(?<!\\)'|\\[^\\']", body):
            raise ValueError(f"Unsupported quoted atom: {text}")
        return body.replace("\\'", "'").replace("\\\\", "\\")
    raise ValueError(f"Not a ground atom: {text}")


def pairs(text: str) -> list[tuple[str, str]]:
    if not text.startswith("[") or not text.endswith("]"):
        raise ValueError(f"Expected a ground fact list: {text}")
    if text == "[]":
        return []
    result = []
    for item in split_args(text[1:-1]):
        match = re.fullmatch(r"([a-z][A-Za-z0-9_]*)-(true|false)", item)
        if match is None:
            raise ValueError(f"Invalid relation fact: {item}")
        result.append(match.groups())
    return result


def load_declarations() -> dict[str, list]:
    records = {name: [] for name in ARITIES}
    for number, line in enumerate(SOURCE.read_text().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("%") or line in DIRECTIVES:
            continue
        match = re.fullmatch(r"([a-z_]+)\((.*)\)\.", line)
        if match is None or match[1] not in records:
            raise ValueError(f"{SOURCE.name}:{number}: unsupported declaration")
        name, body = match.groups()
        args = split_args(body)
        if len(args) != ARITIES[name]:
            raise ValueError(f"{SOURCE.name}:{number}: wrong arity")
        if name == "implies":
            row = (atom(args[0]), pairs(args[1]), pairs(args[2]))
        elif name == "encoder_reads":
            if not re.fullmatch(r"[1-9][0-9]*", args[1]):
                raise ValueError(f"Invalid read index on line {number}")
            row = (atom(args[0]), int(args[1]), atom(args[2]))
        else:
            row = tuple(atom(arg) for arg in args)
        if row in records[name]:
            raise ValueError(f"Duplicate declaration on line {number}")
        records[name].append(row)
    if any(not values for values in records.values()):
        raise ValueError("A required declaration family is empty")
    for name in ("qaida_type", "encoder_type", "implies"):
        names = [row[0] for row in records[name]]
        if len(names) != len(set(names)):
            raise ValueError(f"Duplicate identifier in {name}")
    types = {row[0] for row in records["qaida_type"]}
    encoders = {row[0] for row in records["encoder_type"]}
    fields = {row[1] for row in records["type_field"]}
    if any(t not in types or p not in types for t, p in records["type_extends"]):
        raise ValueError("Type inheritance references an undeclared type")
    if any(t not in types for t, _, _ in records["type_field"]):
        raise ValueError("A field references an undeclared type")
    if any(e not in encoders for e, _, _ in records["encoder_reads"]):
        raise ValueError("A read references an undeclared encoder")
    for encoder in encoders:
        reads = [(i, f) for e, i, f in records["encoder_reads"] if e == encoder]
        if [i for i, _ in reads] != list(range(1, len(reads) + 1)):
            raise ValueError(f"Read indices are not consecutive: {encoder}")
        if len({f for _, f in reads}) != len(reads):
            raise ValueError(f"Duplicate encoder read: {encoder}")
    if any(f not in fields for _, ps, cs in records["implies"] for f, _ in ps + cs):
        raise ValueError("A relation references an undeclared field")
    return records


def lean(value) -> str:
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, int):
        return str(value)
    if isinstance(value, tuple):
        return "(" + ", ".join(map(lean, value)) + ")"
    if isinstance(value, list):
        return "[" + ", ".join(map(lean, value)) + "]"
    raise TypeError(value)


def render() -> str:
    records = load_declarations()
    fixture_text = FIXTURES.read_text()
    situations = [tuple(atom(arg) for arg in split_args(body))
                  for body in re.findall(r"^sit\((.*)\)\.$", fixture_text, re.M)]
    if not situations or any(len(row) != 3 for row in situations):
        raise ValueError("Missing or malformed fixture situations")
    synthetic_reads = []
    for body in re.findall(r"^encoder_reads\((.*)\)\.$", fixture_text, re.M):
        e, i, f = split_args(body)
        synthetic_reads.append((atom(e), int(i), atom(f)))
    synthetic_fields = [tuple(atom(arg) for arg in split_args(body))
                        for body in re.findall(r"^type_field\((.*)\)\.$", fixture_text, re.M)]
    expectations = re.findall(r"fixture_expectation\((\w+),\s*query\(.*?\),\s*expect_(true|false)\)\.",
                              fixture_text, re.S)
    premises = re.findall(r"fixture_premise\((\w+),", fixture_text)
    if len(expectations) != len(re.findall(r"^fixture_expectation\(", fixture_text, re.M)):
        raise ValueError("A fixture expectation could not be parsed")
    expected_rows = [(name, expected == "true", premises.count(name)) for name, expected in expectations]
    output = ["/-! Generated by formal/fixtures/gen_typing_fixtures.py. Do not edit.",
              "Data only: the complete kernel export and explicit fixture assumptions.",
              f"v41_types.pl SHA256: {hashlib.sha256(SOURCE.read_bytes()).hexdigest()}",
              f"v41_typing_fixtures.pl SHA256: {hashlib.sha256(FIXTURES.read_bytes()).hexdigest()}",
              "-/", "", "namespace Usul.Fixtures.Typing.Data", ""]
    declarations = [
        ("qaidaTypes", "String × String", records["qaida_type"]),
        ("typeExtends", "String × String", records["type_extends"]),
        ("typeFields", "String × String × String", records["type_field"]),
        ("typeValues", "String × String", records["type_value"]),
        ("encoderTypes", "String × String", records["encoder_type"]),
        ("encoderReads", "String × Nat × String", records["encoder_reads"]),
        ("implications", "String × List (String × String) × List (String × String)", records["implies"]),
        ("situations", "String × String × String", situations),
        ("syntheticReads", "String × Nat × String", synthetic_reads),
        ("syntheticFields", "String × String × String", synthetic_fields),
        ("referenceExpectations", "String × Bool × Nat", expected_rows),
    ]
    for name, element_type, rows in declarations:
        output.append(f"def {name} : List ({element_type}) := [")
        output.append(",\n".join("  " + lean(row) for row in rows))
        output.extend(["]", ""])
    output.extend(["end Usul.Fixtures.Typing.Data", ""])
    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if generated Lean data is stale")
    args = parser.parse_args()
    expected = render()
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text() != expected:
            raise SystemExit(f"Stale {OUTPUT.relative_to(ROOT)}; run {Path(__file__).relative_to(ROOT)}")
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(expected)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error
