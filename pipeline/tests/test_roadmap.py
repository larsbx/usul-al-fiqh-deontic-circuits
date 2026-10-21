"""The roadmaps stay consistent across the parallel tracks (docs/roadmap-tracks.json): each is linked
from the hub, its milestones and dependencies resolve, and a change to a track's paths updates its
roadmap (or says why not)."""

from pathlib import Path

import pytest

from usul_corpus import roadmap

ROOT = Path(__file__).resolve().parents[2]


def test_the_roadmaps_are_consistent():
    assert roadmap.check(ROOT) == []


def test_every_registry_track_is_declared():
    assert roadmap.registry_tracks(ROOT) <= {t["registry"] for t in roadmap.load(ROOT)["tracks"].values() if "registry" in t}


DOC = """# R
## 3. Milestones
#### M0 · Registry ⟵ —
#### M1 · Logic ⟵ M0
#### M2 · Kernel ⟵ M0, M1, uṣūl M5, existing Milestone 1b
### Status (2026-10-13)
| Milestone | State |
|---|---|
| M1 logic | done |
| R0 refactor | open |
```mermaid
graph TD
  M0[M0 Registry] --> M1[M1 Logic]
  M0 --> M2
  M1 --> M2
```
"""


def test_the_dag_may_draw_a_dependency_on_another_track_the_headings_state():
    drawn = DOC.replace("  M1 --> M2\n", "  M1 --> M2\n  M5 --> M2\n")
    assert roadmap.doc_errors("t", drawn, "M") == []
    assert any("mermaid" in e for e in roadmap.doc_errors("t", drawn.replace("M5 --> M2", "M6 --> M2"), "M"))


def test_milestones_parse_with_their_dependencies():
    assert roadmap.milestones(DOC, "M") == {"M0": set(), "M1": {"M0"}, "M2": {"M0", "M1"}}
    assert roadmap.cross(DOC) == {("M2", "usul", "M5")}


@pytest.mark.parametrize("bad, err", [
    (DOC.replace("⟵ M0, M1,", "⟵ M0, M7,"), "M2 depends on unknown M7"),
    (DOC.replace("#### M0 · Registry ⟵ —", "#### M0 · Registry ⟵ M2"), "cycle"),
    (DOC.replace("  M1 --> M2\n", ""), "mermaid"),
    (DOC.replace("| M1 logic |", "| M9 logic |"), "status row M9"),
    (DOC.replace("#### M1 · Logic ⟵ M0", "#### M1 · Logic ⟵ M0\n#### M1 · Again ⟵ M0"), "M1 twice"),
])
def test_a_broken_roadmap_says_where(bad, err):
    assert any(err in e for e in roadmap.doc_errors("t", bad, "M"))
    assert roadmap.doc_errors("t", DOC, "M") == []


TRACKS = {"hub": "docs/roadmap.md", "tracks": {
    "usul": {"roadmap": "docs/roadmap-usul.md", "paths": ["formal/lean/Usul/**", "corpus/mahall/**"]},
    "hadith": {"roadmap": "docs/roadmap-hadith.md", "paths": ["formal/lean/Hadith/**", "pipeline/usul_corpus/grading.py"]}}}


def test_a_change_to_a_tracks_paths_updates_its_roadmap():
    assert roadmap.stale(TRACKS, {"formal/lean/Usul/Seam.lean"}, waived=False) == \
        ["formal/lean/Usul/Seam.lean (usul) changed, but docs/roadmap-usul.md did not"]
    assert roadmap.stale(TRACKS, {"formal/lean/Usul/Seam.lean", "docs/roadmap-usul.md"}, waived=False) == []


def test_each_track_answers_for_its_own_paths_and_an_unowned_path_for_none():
    changed = {"corpus/mahall/graph.json", "pipeline/usul_corpus/grading.py", "docs/roadmap-hadith.md"}
    assert roadmap.stale(TRACKS, changed, waived=False) == \
        ["corpus/mahall/graph.json (usul) changed, but docs/roadmap-usul.md did not"]
    assert roadmap.stale(TRACKS, {"Makefile", "README.md"}, waived=False) == []


def test_a_path_belongs_to_one_track():
    """Each path answers to its own roadmap: two tracks claiming a file is an error, not a choice."""
    shared = {**TRACKS, "tracks": {**TRACKS["tracks"], "hadith": {**TRACKS["tracks"]["hadith"],
                                                                  "paths": ["corpus/mahall/*.json"]}}}
    assert roadmap.overlaps(shared, ["corpus/mahall/graph.json", "Makefile"]) == \
        ["corpus/mahall/graph.json is claimed by usul and hadith"]
    assert roadmap.overlaps(TRACKS, ["corpus/mahall/graph.json"]) == []


def test_a_roadmap_unchanged_trailer_waives_the_rule():
    assert roadmap.stale(TRACKS, {"formal/lean/Hadith/Grade.lean"}, waived=True) == []
    assert roadmap.waived("Fix a typo\n\nRoadmap-Unchanged: comment only\n")
    assert not roadmap.waived("Fix a typo\n\nRoadmap-Unchanged:\n")


def test_each_roadmap_lists_the_paths_its_track_owns_as_the_manifest_does():
    """The paths block of each roadmap is generated from docs/roadmap-tracks.json, so it cannot drift."""
    tracks = roadmap.load(ROOT)
    for t, v in tracks["tracks"].items():
        assert roadmap.paths_block(tracks, t) in (ROOT / v["roadmap"]).read_text(encoding="utf-8"), t


def test_the_paths_block_groups_by_area_and_is_replaced_in_place():
    block = roadmap.paths_block(TRACKS, "hadith")
    assert block.startswith(roadmap.BEGIN) and block.endswith(roadmap.END)
    assert "| `formal/lean/Hadith/` | `**` |" in block and "| `pipeline/usul_corpus/` | `grading.py` |" in block
    doc = f"# H\n\nIntro.\n\n{roadmap.BEGIN}\nold\n{roadmap.END}\n\n## 0. Scope\n"
    assert roadmap.with_paths(doc, block) == doc.replace(f"{roadmap.BEGIN}\nold\n{roadmap.END}", block)
    assert roadmap.with_paths("# H\n\nIntro.\n\n## 0. Scope\n", block) == f"# H\n\nIntro.\n\n{block}\n\n## 0. Scope\n"
    assert any("paths block" in e for e in roadmap.doc_errors("t", "# H\n", "M", paths=block))
