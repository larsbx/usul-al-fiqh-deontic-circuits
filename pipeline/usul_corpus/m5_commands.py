"""Candidate M5 capabilities and immutable receipts; no live case is reclassified."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from . import takhrij

PLAN = "worklists/lahham_m5_commands_plan.json"
WITNESS = "openiti-lahham-shamela8526"
QAIDA = takhrij.LAHHAM.format(43)
FARS = {QAIDA + f".f{i:03d}" for i in (1, 3, 4, 7)}
ENCODERS_BY_FAR = dict(zip(
    [QAIDA + f".f{i:03d}" for i in (1, 3, 4, 7)],
    ["command_nonverbal_usage", "command_prophetic_act_usage",
     "command_obligation_status", "command_intended_usage"],
))


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def case_sha256(case: dict) -> str:
    return sha256(json.dumps(case, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode())


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate(plan: dict, corpus: Path) -> None:
    """Check candidate scope, source locks, original case receipts, fixtures and review gaps."""
    _require(plan["schema_version"] == 1 and plan["status"] == "candidate", "candidate plan required")
    _require(plan["scope"] == "capability fixtures only; six live gaps remain open", "scope changed")
    _require(plan["source"]["witness"] == WITNESS, "wrong source witness")
    lock = json.loads((corpus / "lock.json").read_text())["witnesses"][WITNESS]
    _require(all(plan["source"][k] == lock[k] for k in ("url", "bytes", "sha256")), "source lock changed")
    raw = (corpus / f"records/{WITNESS}.jsonl").read_bytes()
    _require(sha256(raw) == plan["records_sha256"], "source record receipt changed")
    records = {r["id"]: r for r in map(json.loads, raw.decode().splitlines())}
    cases = {c["far"]: c for c in takhrij.load(corpus)}
    receipts = plan["case_receipts"]
    _require(len(receipts) == len(FARS) and {r["far"] for r in receipts} == FARS, "case receipt set changed")
    for receipt in receipts:
        far = receipt["far"]
        origin = receipt["original_case"]
        _require(origin["far"] == far and origin["class"] == "missing_rule", "wrong original case")
        _require(case_sha256(origin) == receipt["original_case_sha256"], "original case hash changed")
        _require(cases[far] == origin, "live case changed without an explicit revisit")
        _require(receipt["gap_status"] == "open" and receipt["needs"] == origin["needs"], "gap was promoted")
        _require(receipt["record_locator"] == records[far]["locator"], "record locator changed")
        _require(receipt["case_ar_sha256"] == sha256(records[far]["case_ar"].encode()), "case excerpt changed")
        _require(receipt["capability_encoder"] == ENCODERS_BY_FAR[far], "wrong capability encoder")
        _require(not set(origin["needs"]) <= takhrij.provides(), "original gap was silently declared provided")
    questions = plan["review_questions"]
    ids = {q["id"] for q in questions}
    _require(len(ids) == len(questions) == 4, "review question set changed")
    _require(all(q["status"] == "open" for q in questions), "human review remains open")
    _require({f for q in questions for f in q["scope"]} == FARS, "review scope changed")
    _require(all(set(r["review_questions"]) <= ids and r["review_questions"] for r in receipts), "review link missing")
    by_question = {q["id"]: set(q["scope"]) for q in questions}
    _require(all(all(r["far"] in by_question[q] for q in r["review_questions"]) for r in receipts),
             "review link has another case's scope")
    selection = plan["selection"]
    _require(len(selection) == 1 and selection[0]["qaida"] == QAIDA, "wrong selected qaida")
    _require(selection[0]["status"] == "candidate" and selection[0]["reading"], "reading status changed")
    fixtures = plan["fixtures"]
    _require(len({f["id"] for f in fixtures}) == len(fixtures), "duplicate fixture id")
    _require({f["far"] for f in fixtures} == FARS, "fixture scope changed")
    by_far = {r["far"]: r["capability_encoder"] for r in receipts}
    for fixture in fixtures:
        _require(fixture["encoder"] == by_far[fixture["far"]], "fixture uses another case's encoder")
        enc = takhrij.ENCODERS[fixture["encoder"]]
        facts = fixture["facts"]
        _require(set(facts) == set(enc["facts"]), "fixture fact keys changed")
        _require(all(any(type(facts[k]) is type(v) and facts[k] == v for v in dom)
                     for k, dom in enc["facts"].items()), "fixture fact outside typed domain")
        _require(any(type(fixture["expected"]) is type(v) and fixture["expected"] == v for v in enc["out"]),
                 "fixture output outside typed domain")
        _require(enc["py"](facts) == fixture["expected"], "fixture contradicts the candidate encoder")
        _require(fixture["source_evidence"], "fixture lacks source evidence")
        for evidence in fixture["source_evidence"]:
            excerpt = evidence["excerpt_ar"]
            _require(0 < len(excerpt) <= 400 and evidence["ref"].startswith(f"src:{WITNESS}/"), "invalid source excerpt")
            _require(sha256(excerpt.encode()) == evidence["excerpt_sha256"], "evidence hash changed")


def validate_source(plan: dict, data: bytes) -> None:
    """Replay all evidence against the full locked source and its closing-page markers."""
    from .openiti import parse_markdown
    from .segment import _number

    _require(len(data) == plan["source"]["bytes"] and sha256(data) == plan["source"]["sha256"], "full source hash changed")
    text = data.decode("utf-8")
    headers = list(re.finditer(r"^###[ \t]*(\|+)[ \t]*(.*)$", text, re.M))
    sections = parse_markdown(text)
    _require(len(headers) == len(sections), "source header alignment changed")
    spans = []
    for i, section in enumerate(sections):
        if section.level == 1 and "القاعدة" in section.title:
            number, _ = _number(re.sub(r"<[^>]*>", "", section.text))
            if number == 43:
                end = next((headers[j].start() for j in range(i + 1, len(headers))
                            if len(headers[j][1]) == 1), len(text))
                spans.append((headers[i].start(), end))
    _require(len(spans) == 1, "Q43 source span is ambiguous")
    lo, hi = spans[0]
    indices = [i for i, ch in enumerate(text) if "ء" <= ch <= "ي"]
    letters = "".join(text[i] for i in indices)
    for fixture in plan["fixtures"]:
        for evidence in fixture["source_evidence"]:
            excerpt = re.sub(r"[^ء-ي]", "", evidence["excerpt_ar"])
            _require(bool(excerpt), "source excerpt contains no Arabic letters")
            start = letters.find(excerpt)
            found = False
            while start >= 0:
                end = indices[start + len(excerpt) - 1]
                if lo <= indices[start] <= end < hi:
                    page = re.search(r"PageV(\d+)P(\d+)", text[end:])
                    if page and evidence["ref"] == f"src:{WITNESS}/v{page[1]}:p{page[2]}":
                        found = True
                        break
                start = letters.find(excerpt, start + 1)
            _require(found, f"source evidence or page differs: {fixture['id']}")


def fetch_locked_source(plan: dict, corpus: Path, cache: Path) -> bytes:
    """Restore a cache entry without changing any source lock or corpus record."""
    from .fetch import fetch

    registry = json.loads((corpus / "registry.json").read_text())
    witness = next(w for work in registry["works"] for w in work["witnesses"] if w["id"] == WITNESS)
    entry = fetch(witness, cache)
    _require(all(entry[k] == plan["source"][k] for k in ("url", "bytes", "sha256")), "download differs from locked source")
    return (cache / f"{WITNESS}.txt").read_bytes()
