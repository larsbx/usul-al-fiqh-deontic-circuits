"""Validate and export the candidate fiqh act reference; never admit a ruling.

Run ``python -m usul_corpus.act_reference --out ../.cache/fiqh-act-reference``
from pipeline/. Source-record and lock agreement are checked locally. Full source
bytes are checked only with --witness-dir, using <witness-id>.txt filenames.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REFERENCE = "corpus/proposals/fiqh-acts/reference.json"
LEAN = "formal/lean/Usul/IDA.lean"


class ReferenceError(ValueError):
    """The candidate reference disagrees with its declared inputs."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ReferenceError(message)


def indexed(rows: list, key: str, context: str) -> dict:
    require(isinstance(rows, list), f"{context}: expected a list")
    require(all(isinstance(row, dict) and isinstance(row.get(key), str)
                and row[key].strip() for row in rows), f"{context}: missing {key}")
    result = {row[key]: row for row in rows}
    require(len(result) == len(rows), f"{context}: duplicate {key}")
    return result


def strings(values: list, context: str) -> None:
    require(isinstance(values, list) and all(isinstance(v, str) and v.strip()
                                            for v in values), f"{context}: expected names")
    require(len(set(values)) == len(values), f"{context}: duplicate name")


def page_span(value: object, context: str) -> None:
    require(isinstance(value, list) and len(value) == 2
            and all(type(x) is int and x > 0 for x in value)
            and value[0] <= value[1], f"{context}: invalid page span")


def topic_roots(labels_document: dict, topics_document: dict) -> dict[str, list[str]]:
    """Follow every broader edge, including edges crossing legacy label kinds."""
    labels = indexed(labels_document["labels"], "id", "concepts")
    roots = indexed(topics_document["abwab"], "id", "topics")
    require(not (labels.keys() & roots.keys()), "concept/topic identifier collision")
    memo: dict[str, set[str]] = {}

    def visit(ident: str, active: frozenset[str]) -> set[str]:
        if ident in roots:
            return {ident}
        require(ident not in active, f"broader graph cycle at {ident}")
        if ident in memo:
            return memo[ident]
        require(ident in labels, f"unresolved broader reference: {ident}")
        parents = labels[ident].get("broader")
        strings(parents, f"{ident} broader")
        found: set[str] = set()
        for parent in parents:
            found.update(visit(parent, active | {ident}))
        require(bool(found), f"{ident}: no reachable topic root")
        memo[ident] = found
        return found

    return {ident: sorted(visit(ident, frozenset())) for ident in labels}


def load_inputs(repo: Path) -> tuple[dict, dict[str, bytes]]:
    inputs: dict[str, bytes] = {}

    def read(path: str) -> str:
        inputs[path] = (repo / path).read_bytes()
        return inputs[path].decode("utf-8")

    data = {name: json.loads(read(path)) for name, path in (
        ("reference", REFERENCE), ("labels", "corpus/mahall/labels/all.json"),
        ("topics", "corpus/mahall/abwab.json"), ("registry", "corpus/registry.json"),
        ("locks", "corpus/lock.json"))}
    lean = read(LEAN)
    declaration = re.search(r"inductive RefKind where\s+(.*?)\n\s*deriving\b", lean, re.S)
    require(declaration is not None, "cannot locate IDA.RefKind declaration")
    constructors = re.findall(r"\|\s*(\w+)", declaration[1])
    require(re.fullmatch(r"(?:\s*\|\s*\w+)+\s*", declaration[1]) is not None
            and bool(constructors) and len(set(constructors)) == len(constructors),
            "cannot read IDA.RefKind constructors")
    data["ref_kinds"] = set(constructors)
    # Bind the code actually executing, also when --repo names another checkout.
    inputs["pipeline/usul_corpus/act_reference.py"] = Path(__file__).read_bytes()
    read("pipeline/tests/test_act_reference.py")
    read(".github/workflows/fiqh-act-reference.yml")
    witnesses = {locus["witness"] for proposal in data["reference"]["proposals"]
                 for locus in proposal["source_loci"]}
    records = []
    for witness in sorted(witnesses):
        require(isinstance(witness, str) and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", witness),
                "invalid record witness identifier")
        records.extend(json.loads(line) for line in
                       read(f"corpus/records/{witness}.jsonl").splitlines() if line.strip())
    data["records"] = indexed(records, "id", "source records")
    return data, inputs


def validate(data: dict) -> dict:
    reference, labels_document = data["reference"], data["labels"]
    require(reference.get("schema_version") == "fiqh-act-reference-1", "unknown reference schema")
    for field, expected in (("status", "candidate"), ("admitted", False), ("design_only", True),
                            ("compiled", False), ("mappings_admitted", False)):
        require(type(reference.get(field)) is type(expected) and reference[field] == expected,
                f"reference {field}: candidate boundary violated")
    require(labels_document.get("status") == data["topics"].get("status") == "candidate",
            "legacy catalogue must retain its candidate status")
    labels = indexed(labels_document["labels"], "id", "concepts")
    topics = indexed(data["topics"]["abwab"], "id", "topics")
    require(bool(labels) and bool(topics), "reference requires nonempty concepts and topics")
    reachable = topic_roots(labels_document, data["topics"])
    registered = {(work["id"], witness["id"])
                  for work in data["registry"]["works"] for witness in work.get("witnesses", [])}
    pins = indexed(reference["source_pins"], "witness", "source pins")
    for witness, pin in pins.items():
        require((pin["work"], witness) in registered, f"{witness}: unregistered work/witness")
        lock = data["locks"]["witnesses"].get(witness)
        require(lock is not None, f"{witness}: no source lock")
        require(type(pin.get("bytes")) is int and pin["bytes"] > 0
                and re.fullmatch(r"[0-9a-f]{64}", pin.get("sha256", "")) is not None,
                f"{witness}: invalid source pin")
        for field in ("url", "bytes", "sha256"):
            require(pin.get(field) == lock.get(field), f"{witness}: source pin {field} differs from lock")

    def pinned_locus(locus: dict, context: str) -> None:
        witness = locus.get("witness")
        require(witness in pins and locus.get("work") == pins[witness]["work"],
                f"{context}: work/witness not among declared source pins")
        page_span(locus.get("page_span"), context)

    for locus in reference["methodological_loci"]:
        pinned_locus(locus, "methodological locus")
        require(locus.get("status") == "candidate" and type(locus.get("volume")) is int
                and locus["volume"] > 0 and isinstance(locus.get("use"), str) and locus["use"].strip(),
                "methodological locus: invalid status, volume or use")
    proposals = indexed(reference["proposals"], "proposed_kind_id", "proposals")
    require(type(reference.get("count")) is int and reference["count"] == len(proposals),
            "proposal count differs from inventory")
    representable = 0
    for ident, proposal in proposals.items():
        require(proposal.get("status") == "candidate" and proposal.get("admitted") is False
                and proposal.get("target_sort") == "act_description", f"{ident}: candidate boundary violated")
        version = proposal.get("proposed_definition_version")
        require(type(version) is int and version > 0, f"{ident}: invalid definition version")
        legacy_ids = proposal["legacy_concept_ids"]
        strings(legacy_ids, f"{ident} legacy concepts")
        require(set(proposal["legacy_kinds"]) == set(legacy_ids), f"{ident}: legacy kind keys differ")
        for legacy in legacy_ids:
            require(legacy in labels and proposal["legacy_kinds"][legacy] == labels[legacy]["kind"],
                    f"{ident}: unknown concept or changed legacy kind {legacy}")
        topic_ids = proposal.get("legacy_topic_ids", [])
        strings(topic_ids, f"{ident} legacy topics")
        require(all(topic in topics for topic in topic_ids), f"{ident}: unknown topic")
        strings(proposal["family_tags"], f"{ident} families")
        roles, bridge = proposal["parameter_roles_proposed"], proposal["ida_bridge"]
        strings(roles, f"{ident} roles")
        require(bridge.get("status") == "candidate" and bridge.get("profile_admitted") is False,
                f"{ident}: bridge candidate boundary violated")
        require(bridge.get("operation_symbol") == {"space": f"fiqh.act.candidate.v{version}", "name": ident},
                f"{ident}: operation symbol does not bind kind and definition version")
        parameters = bridge["parameters"]
        require(isinstance(parameters, list) and all(isinstance(p, dict) for p in parameters)
                and [p.get("role") for p in parameters] == roles, f"{ident}: role order or membership differs")
        for parameter in parameters:
            require("ref_kind" in parameter, f"{ident}: missing ref_kind")
            kind = parameter["ref_kind"]
            if kind is None:
                reason = parameter.get("unresolved_reason")
                require(isinstance(reason, str) and bool(reason.strip()), f"{ident}: unresolved role lacks a reason")
            else:
                require(isinstance(kind, str) and kind in data["ref_kinds"], f"{ident}: unsupported RefKind {kind}")
        complete = all(p["ref_kind"] is not None for p in parameters)
        require(bridge.get("representable") is complete, f"{ident}: representable flag disagrees with unresolved roles")
        representable += complete
        require(bool(proposal["source_loci"]), f"{ident}: no source locus")
        for locus in proposal["source_loci"]:
            pinned_locus(locus, ident)
            require(locus.get("mapping_status") == "candidate"
                    and locus.get("basis") == "chapter_or_passage_mapping", f"{ident}: source mapping boundary violated")
            record = data["records"].get(locus.get("record_id"))
            require(record is not None, f"{ident}: unresolved source record")
            for field in ("work", "witness", "locator", "page_span"):
                require(locus.get(field) == record.get(field), f"{ident}: source record {field} differs")
    cases = indexed(reference["normalization_cases"], "legacy_concept_id", "normalization cases")
    for legacy, case in cases.items():
        require(legacy in labels and case.get("interpretation_status") == "candidate"
                and case.get("preserve_label") is True, f"{legacy}: normalization boundary violated")
        for field in ("proposed_kind_ids", "required_qualifications", "unresolved_target_sorts"):
            strings(case[field], f"{legacy} {field}")
        require(all(kind in proposals for kind in case["proposed_kind_ids"]), f"{legacy}: unknown proposed kind")
    counts = Counter(label["kind"] for label in labels.values())
    return {"topics_by_concept": reachable,
            "inventory_counts": {"concepts": len(labels), "act_labels": counts["act"],
                                 "item_labels": counts["item"], "issue_labels": counts["issue"], "topics": len(topics)},
            "proposal_counts": {"total": len(proposals), "representable": representable,
                                "unresolved": len(proposals) - representable},
            "normalization_cases": len(cases)}


def provenance(repo: Path, inputs: dict[str, bytes]) -> dict:
    def git(*args: str) -> subprocess.CompletedProcess:
        return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, check=False)

    try:
        result = git("rev-parse", "HEAD")
        revision = result.stdout.decode().strip() if result.returncode == 0 else None
    except OSError:
        revision = None
    files = []
    for path, content in sorted(inputs.items()):
        committed = git("show", f"{revision}:{path}") if revision else None
        files.append({"path": path, "bytes": len(content), "sha256": hashlib.sha256(content).hexdigest(),
                      "matches_head": bool(committed is not None and committed.returncode == 0
                                           and committed.stdout == content)})
    return {"repository_revision": revision, "inputs_match_head": bool(revision and files) and all(f["matches_head"] for f in files),
            "inputs_match_head_scope": "Repository files listed in input_files; witness bytes are reported separately.",
            "input_files": files}


def witness_observations(pins: list[dict], witness_dir: Path | None) -> list[dict]:
    observations = []
    for pin in pins:
        row = {**pin, "byte_identity_status": "not_checked", "source_interpretation_admitted": False}
        if witness_dir is not None:
            path = witness_dir / f"{pin['witness']}.txt"
            require(path.is_file(), f"missing requested witness bytes: {pin['witness']}")
            content = path.read_bytes()
            digest = hashlib.sha256(content).hexdigest()
            require(len(content) == pin["bytes"] and digest == pin["sha256"],
                    f"witness bytes differ from lock: {pin['witness']}")
            row.update(byte_identity_status="matches_existing_lock", observed_bytes=len(content), observed_sha256=digest)
        observations.append(row)
    return observations


def export(output: Path, data: dict, checked: dict, report: dict) -> None:
    output.mkdir(parents=True, exist_ok=True)

    def dump(name: str, value: object) -> None:
        (output / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    concepts = [{"id": label["id"], "label_ar": label["ar"], "label_en": label["en"],
                 "legacy_kind": label["kind"], "broader": label["broader"],
                 "reachable_topic_ids": checked["topics_by_concept"][label["id"]],
                 "source_references_as_recorded": label.get("nass", []),
                 "unanchored_reason_as_recorded": label.get("unanchored"),
                 "status": "candidate", "admitted_by_this_reference": False,
                 "legacy_record": label} for label in data["labels"]["labels"]]
    acts = [concept for concept in concepts if concept["legacy_kind"] == "act"]
    metadata = {"schema_version": "fiqh-act-catalogue-1", "status": "candidate", "admitted": False,
                "repository_revision": report["repository_revision"], "inputs_match_head": report["inputs_match_head"],
                "input_files": report["input_files"], "inventory_counts": report["inventory_counts"],
                "broader_relation_semantics": "Discovery graph; no semantic subtype relation is asserted."}
    dump("fiqh-concept-catalogue.json", {**metadata, "concepts": concepts})
    dump("fiqh-act-catalogue.json", {**metadata, "acts": acts})
    memberships = Counter(topic for act in acts for topic in act["reachable_topic_ids"])
    topics = [{"id": topic["id"], "label_ar": topic["ar"], "label_en": topic["en"],
               "reachable_legacy_act_labels": memberships[topic["id"]], "status": "candidate"}
              for topic in data["topics"]["abwab"]]
    dump("fiqh-topic-index.json", {**metadata, "topics": topics})
    for name, rows, fields in (("fiqh-act-catalogue.csv", acts, [key for key in concepts[0] if key != "legacy_record"]),
                               ("fiqh-topic-index.csv", topics, list(topics[0]))):
        with (output / name).open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            for row in rows:
                writer.writerow({key: json.dumps(row[key], ensure_ascii=False, separators=(",", ":"))
                                 if isinstance(row[key], (list, dict)) else row[key] for key in fields})
    dump("fiqh-act-type-proposals.json", data["reference"])
    dump("source-verification.json", report)


def audit(repo: Path = REPO, output: Path | None = None, witness_dir: Path | None = None) -> dict:
    data, inputs = load_inputs(repo)
    checked = validate(data)
    observations = witness_observations(data["reference"]["source_pins"], witness_dir)
    report = {"schema_version": "fiqh-act-reference-check-1", "status": "passed",
              "validation_scope": "Candidate inventory, graph, proposed signatures, source-record and lock agreement.",
              **provenance(repo, inputs), **{k: v for k, v in checked.items() if k != "topics_by_concept"},
              "ref_kinds": sorted(data["ref_kinds"]), "source_observations": observations,
              "all_catalogue_source_passages_reverified": False, "new_lean_or_quint_verification": False,
              "mappings_admitted": False}
    if output is not None:
        export(output, data, checked, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=REPO)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--witness-dir", type=Path)
    args = parser.parse_args()
    try:
        report = audit(args.repo.resolve(), args.out, args.witness_dir)
    except (ReferenceError, OSError, KeyError, TypeError, json.JSONDecodeError) as exc:
        parser.exit(1, f"Act reference check failed: {exc}\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
