"""Candidate M5 capabilities and immutable receipts; no live case is reclassified."""

from __future__ import annotations

import hashlib
import json
import re
from itertools import product
from pathlib import Path

from . import takhrij

PLAN = "worklists/lahham_m5_commands_plan.json"
WITNESS = "openiti-lahham-shamela8526"
QAIDA = takhrij.LAHHAM.format(43)
FARS = {QAIDA + f".f{i:03d}" for i in (1, 3, 4, 7)}
BASE_COMMIT = "3a9d11776eb3be21702d3624f4152e276fda00ed"
ORIGINAL_SOURCE = {
    "witness": WITNESS,
    "url": ("https://raw.githubusercontent.com/OpenITI/0825AH/bae1fba53712c020fe43e3e60b37dfe61f2b64a8/"
            "data/0803IbnLahhamCalaDinBacli/0803IbnLahhamCalaDinBacli.Qawacid/"
            "0803IbnLahhamCalaDinBacli.Qawacid.Shamela0008526-ara1"),
    "bytes": 722414,
    "sha256": "d1efbaa04ca15696f92db87137381a77415ca7b3dde39e105d8e503cdcc706b0",
}
ORIGINAL_RECORDS_SHA256 = "9ebb8913504fa536ba8d32d173fadd43868a9af68507333b330ef5df15a6f494"
# Canonical case hashes independently verified at BASE_COMMIT. These anchors live
# outside the mutable work plan, so editing a case and its receipt together fails.
ORIGINAL_CASE_SHA256 = {
    QAIDA + ".f001": "3432b0a46543ccde7f97d0893c50e4a13a3a9e89c83d20ff5bdec5e208ea37cc",
    QAIDA + ".f003": "42faedea481cd1102166866a76dd6f75c8a428cdc69a74ce2cb8b5388590869e",
    QAIDA + ".f004": "6c67447789d873d8dc6778ef86c92bc705baf672195282ba6782e4ef2ba8ce65",
    QAIDA + ".f007": "6541542f5cd5909107f61ba24243afa448e298b15e9744ba3952d11e3abeb15c",
}
REVIEW_BY_FAR = {QAIDA + f".f{n:03d}": f"M5-CMD-Q{n:03d}" for n in (1, 3, 4, 7)}
# Original capability receipts bind each fixture's complete ref/excerpt/hash list.
ORIGINAL_EVIDENCE_SHA256 = {
    "M5-CMD-001-qadiReported-writing": "d6bf886a194eb8c84881710335f375055fe7662416535cdcdcda793aa600552b",
    "M5-CMD-001-qadiReported-gesture": "d6bf886a194eb8c84881710335f375055fe7662416535cdcdcda793aa600552b",
    "M5-CMD-001-jamiWriting-writing": "c1553dc2f5e11f43438b552e009b5d88c8c4cc5ad42021283f646f7c88373db1",
    "M5-CMD-001-jamiWriting-gesture": "c1553dc2f5e11f43438b552e009b5d88c8c4cc5ad42021283f646f7c88373db1",
    "M5-CMD-003-abuBarakat-false": "31f65c5dc019b496a2d0ec56ec0ca33cca4437bee0ffae23a087c18dc3595fc6",
    "M5-CMD-003-abuBarakat-true": "31f65c5dc019b496a2d0ec56ec0ca33cca4437bee0ffae23a087c18dc3595fc6",
    "M5-CMD-003-literalReport-false": "90556b5b2214ee615146a9cb40288b4912930e53f85679a6950549fed96a045b",
    "M5-CMD-003-literalReport-true": "90556b5b2214ee615146a9cb40288b4912930e53f85679a6950549fed96a045b",
    "M5-CMD-003-authorConditional-false": "59ab91acee1b592e853dea7d412856ea3b95ee9506e0bdec429518e502035654",
    "M5-CMD-003-authorConditional-true": "59ab91acee1b592e853dea7d412856ea3b95ee9506e0bdec429518e502035654",
    "M5-CMD-004-qadi-bareCommand-mandub": "5beae3114c1ebf3e808bccdd1943144fa855d1c862a1c18f5ae79df1c29ad2dd",
    "M5-CMD-004-qadi-unqualifiedThreat-mandub": "192a4f759d8ba680e9f1d617bfde8c2a54158098997226ffaa47c0402720cf1f",
    "M5-CMD-004-qadi-wujubLabel-mandub": "192a4f759d8ba680e9f1d617bfde8c2a54158098997226ffaa47c0402720cf1f",
    "M5-CMD-004-qadi-fardLabel-mandub": "192a4f759d8ba680e9f1d617bfde8c2a54158098997226ffaa47c0402720cf1f",
    "M5-CMD-004-qadi-bareCommand-mubah": "5beae3114c1ebf3e808bccdd1943144fa855d1c862a1c18f5ae79df1c29ad2dd",
    "M5-CMD-004-qadi-wujubLabel-none": "192a4f759d8ba680e9f1d617bfde8c2a54158098997226ffaa47c0402720cf1f",
    "M5-CMD-004-abuBarakat-bareCommand-mandub": "5beae3114c1ebf3e808bccdd1943144fa855d1c862a1c18f5ae79df1c29ad2dd",
    "M5-CMD-004-abuBarakat-unqualifiedThreat-mandub": "18a9850d0da6e319005520fd1a155214188e83f3f346f3fdadb406a672057540",
    "M5-CMD-004-abuBarakat-wujubLabel-mandub": "18a9850d0da6e319005520fd1a155214188e83f3f346f3fdadb406a672057540",
    "M5-CMD-004-abuBarakat-fardLabel-mandub": "18a9850d0da6e319005520fd1a155214188e83f3f346f3fdadb406a672057540",
    "M5-CMD-004-abuBarakat-bareCommand-mubah": "5beae3114c1ebf3e808bccdd1943144fa855d1c862a1c18f5ae79df1c29ad2dd",
    "M5-CMD-004-abuBarakat-wujubLabel-none": "18a9850d0da6e319005520fd1a155214188e83f3f346f3fdadb406a672057540",
    "M5-CMD-007-qadiReport-recommendation": "b1e9dbaee32b892869b2dc62e5cc21f89f063cc991843f94e87bb7c0f37a855e",
    "M5-CMD-007-qadiReport-permission": "1b0f0cc13f8f832f7e834e836e21d470edac6d0f02d0488c0d3ef7daab0b7191",
    "M5-CMD-007-karkhiRazi-recommendation": "ddcb83ebdd27926dca6e41c9383ccf26f8d10ca521556305efd2f28510caa2a7",
    "M5-CMD-007-karkhiRazi-permission": "ddcb83ebdd27926dca6e41c9383ccf26f8d10ca521556305efd2f28510caa2a7",
    "M5-CMD-007-abuBarakat-recommendation": "1b0f0cc13f8f832f7e834e836e21d470edac6d0f02d0488c0d3ef7daab0b7191",
    "M5-CMD-007-abuBarakat-permission": "1b0f0cc13f8f832f7e834e836e21d470edac6d0f02d0488c0d3ef7daab0b7191",
    "M5-CMD-007-qadiArgument-recommendation": "8263bee512506905aa76e8a7d885e0d522477f88e5ee553dd28a27246c77dc4e",
    "M5-CMD-007-qadiArgument-permission": "8263bee512506905aa76e8a7d885e0d522477f88e5ee553dd28a27246c77dc4e",
}
ENCODERS_BY_FAR = dict(zip(
    [QAIDA + f".f{i:03d}" for i in (1, 3, 4, 7)],
    ["command_nonverbal_usage", "command_prophetic_act_usage",
     "command_obligation_status", "command_intended_usage"],
))


def required_fixtures() -> dict[str, dict]:
    """The complete source-contrast input matrix, independently of plan contents."""
    required = {}

    def add(n: int, label: str, facts: dict) -> None:
        required[f"M5-CMD-{n:03d}-{label}"] = {"far": QAIDA + f".f{n:03d}", "facts": facts}

    for reading, form in product(("qadiReported", "jamiWriting"), ("writing", "gesture")):
        add(1, f"{reading}-{form}", dict(reading=reading, form=form))
    for reading, premise in product(("abuBarakat", "literalReport", "authorConditional"), (False, True)):
        add(3, f"{reading}-{str(premise).lower()}", dict(reading=reading, imitation_established=premise))
    for reading in ("qadi", "abuBarakat"):
        for expression in ("bareCommand", "unqualifiedThreat", "wujubLabel", "fardLabel"):
            add(4, f"{reading}-{expression}-mandub", dict(reading=reading, expression=expression, qarina="mandub"))
        add(4, f"{reading}-bareCommand-mubah", dict(reading=reading, expression="bareCommand", qarina="mubah"))
        add(4, f"{reading}-wujubLabel-none", dict(reading=reading, expression="wujubLabel", qarina="none"))
    for reading, intended in product(("qadiReport", "karkhiRazi", "abuBarakat", "qadiArgument"),
                                     ("recommendation", "permission")):
        add(7, f"{reading}-{intended}", dict(reading=reading, intended=intended))
    return required


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def case_sha256(case: dict) -> str:
    return sha256(json.dumps(case, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode())


def check_evidence_anchor(fixture: dict) -> None:
    """Pin the original supporting quotations, not just any passage in the chapter."""
    digest = sha256(json.dumps(fixture["source_evidence"], ensure_ascii=False,
                               sort_keys=True, separators=(",", ":")).encode())
    _require(digest == ORIGINAL_EVIDENCE_SHA256.get(fixture["id"]),
             "fixture evidence differs from original anchor")


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate(plan: dict, corpus: Path) -> None:
    """Check candidate scope, source locks, original case receipts, fixtures and review gaps."""
    _require(plan["schema_version"] == 1 and plan["status"] == "candidate", "candidate plan required")
    _require(plan["base_commit"] == BASE_COMMIT, "original contribution anchor changed")
    _require(plan["scope"] == "capability fixtures only; four original command gaps remain open", "scope changed")
    _require(plan["source"]["witness"] == WITNESS, "wrong source witness")
    lock = json.loads((corpus / "lock.json").read_text())["witnesses"][WITNESS]
    _require(all(plan["source"][k] == lock[k] for k in ("url", "bytes", "sha256")), "source lock changed")
    _require(all(plan["source"][k] == v for k, v in ORIGINAL_SOURCE.items()), "source contribution anchor changed")
    raw = (corpus / f"records/{WITNESS}.jsonl").read_bytes()
    _require(sha256(raw) == plan["records_sha256"], "source record receipt changed")
    _require(plan["records_sha256"] == ORIGINAL_RECORDS_SHA256, "source record differs from base anchor")
    records = {r["id"]: r for r in map(json.loads, raw.decode().splitlines())}
    cases = {c["far"]: c for c in takhrij.load(corpus)}
    receipts = plan["case_receipts"]
    _require(len(receipts) == len(FARS) and {r["far"] for r in receipts} == FARS, "case receipt set changed")
    for receipt in receipts:
        far = receipt["far"]
        origin = receipt["original_case"]
        _require(origin["far"] == far and origin["class"] == "missing_rule", "wrong original case")
        _require(case_sha256(origin) == receipt["original_case_sha256"], "original case hash changed")
        _require(receipt["original_case_sha256"] == ORIGINAL_CASE_SHA256[far], "original case differs from base anchor")
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
    _require({q["id"]: q["scope"] for q in questions} ==
             {ident: [far] for far, ident in REVIEW_BY_FAR.items()}, "review question mapping changed")
    _require(all(isinstance(q["question"], str) and q["question"].strip() for q in questions),
             "review question is empty")
    _require(all(set(r["review_questions"]) <= ids and r["review_questions"] for r in receipts), "review link missing")
    by_question = {q["id"]: set(q["scope"]) for q in questions}
    _require(all(all(r["far"] in by_question[q] for q in r["review_questions"]) for r in receipts),
             "review link has another case's scope")
    _require(all(r["review_questions"] == [REVIEW_BY_FAR[r["far"]]] for r in receipts),
             "case-specific review link changed")
    selection = plan["selection"]
    _require(len(selection) == 1 and selection[0]["qaida"] == QAIDA, "wrong selected qaida")
    _require(selection[0]["status"] == "candidate" and selection[0]["reading"], "reading status changed")
    fixtures = plan["fixtures"]
    _require(len({f["id"] for f in fixtures}) == len(fixtures), "duplicate fixture id")
    required = required_fixtures()
    _require({f["id"] for f in fixtures} == required.keys(), "required fixture set changed")
    _require({f["far"] for f in fixtures} == FARS, "fixture scope changed")
    by_far = {r["far"]: r["capability_encoder"] for r in receipts}
    for fixture in fixtures:
        _require(fixture["encoder"] == by_far[fixture["far"]], "fixture uses another case's encoder")
        enc = takhrij.ENCODERS[fixture["encoder"]]
        facts = fixture["facts"]
        _require(set(facts) == set(enc["facts"]), "fixture fact keys changed")
        _require(all(any(type(facts[k]) is type(v) and facts[k] == v for v in dom)
                     for k, dom in enc["facts"].items()), "fixture fact outside typed domain")
        _require({"far": fixture["far"], "facts": facts} == required[fixture["id"]], "fixture input matrix changed")
        _require(any(type(fixture["expected"]) is type(v) and fixture["expected"] == v for v in enc["out"]),
                 "fixture output outside typed domain")
        _require(enc["py"](facts) == fixture["expected"], "fixture contradicts the candidate encoder")
        _require(fixture["source_evidence"], "fixture lacks source evidence")
        for evidence in fixture["source_evidence"]:
            excerpt = evidence["excerpt_ar"]
            _require(0 < len(excerpt) <= 400 and evidence["ref"].startswith(f"src:{WITNESS}/"), "invalid source excerpt")
            _require(sha256(excerpt.encode()) == evidence["excerpt_sha256"], "evidence hash changed")
        check_evidence_anchor(fixture)


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
        check_evidence_anchor(fixture)
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
    """Explicitly redownload the pinned witness without changing locks or records."""
    from .fetch import fetch

    registry = json.loads((corpus / "registry.json").read_text())
    witness = next(w for work in registry["works"] for w in work["witnesses"] if w["id"] == WITNESS)
    entry = fetch(witness, cache, refresh=True)
    _require(all(entry[k] == plan["source"][k] for k in ("url", "bytes", "sha256")), "download differs from locked source")
    return (cache / f"{WITNESS}.txt").read_bytes()
