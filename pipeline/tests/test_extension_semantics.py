"""Independent finite powerset oracle for ADR 0001 (not a jurisprudential model).

Exhaust all labelled AFs with 0..3 nodes, including self attacks: 531 graphs.
Run: python -m pytest pipeline/tests/test_extension_semantics.py -q
"""
from itertools import combinations


def semantics(n, edges):
    universe = frozenset(range(n))
    edges = set(edges)
    sets = [frozenset(xs) for k in range(n + 1) for xs in combinations(range(n), k)]

    def cf(s):
        return not any(a in s and b in s for a, b in edges)

    def defended(s):
        return frozenset(a for a in universe if all(
            any((c, b) in edges for c in s) for b in universe if (b, a) in edges))

    admissible = [s for s in sets if cf(s) and s <= defended(s)]
    complete = [s for s in admissible if defended(s) == s]
    preferred = [s for s in admissible if not any(s < t for t in admissible)]
    stable = [s for s in sets if cf(s) and all(
        any((b, a) in edges for b in s) for a in universe - s)]
    grounded = frozenset()
    while defended(grounded) != grounded:
        grounded = defended(grounded)
    return grounded, complete, preferred, stable


def test_named_boundaries():
    fixtures = [
        (3, [(0, 1), (1, 2), (2, 0)], set(), [set()], []),
        (2, [(0, 1), (1, 0)], set(), [{0}, {1}], [{0}, {1}]),
        (3, [], {0, 1, 2}, [{0, 1, 2}], [{0, 1, 2}]),
        (3, [(0, 1), (1, 0)], {2}, [{0, 2}, {1, 2}], [{0, 2}, {1, 2}]),
        (4, [(0, 1), (1, 2), (2, 0), (3, 0)], {1, 3}, [{1, 3}], [{1, 3}]),
        (1, [(0, 0)], set(), [set()], []),
        (4, [(0, 1), (1, 0), (0, 2), (1, 2), (2, 3)], set(),
         [{0, 3}, {1, 3}], [{0, 3}, {1, 3}]),
    ]
    for n, edges, g, p, s in fixtures:
        actual_g, _, actual_p, actual_s = semantics(n, edges)
        assert actual_g == g
        assert actual_p == p
        assert actual_s == s
    # Grounded can be strictly smaller than skeptical preferred acceptance.
    g, _, p, _ = semantics(4, fixtures[-1][1])
    assert g < frozenset.intersection(*p) == {3}


def test_all_afs_up_to_three_nodes():
    count = 0
    for n in range(4):
        possible = [(a, b) for a in range(n) for b in range(n)]
        for mask in range(1 << len(possible)):
            edges = [e for i, e in enumerate(possible) if mask & (1 << i)]
            g, complete, preferred, stable = semantics(n, edges)
            assert g in complete
            assert all(g <= e for e in complete)
            assert preferred
            assert all(e in preferred for e in stable)
            assert all(e in complete for e in preferred)
            count += 1
    assert count == 531
