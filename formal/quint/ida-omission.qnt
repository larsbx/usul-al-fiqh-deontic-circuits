// Bounded independent omission model for one exact opportunity.
module idaOmission {
  type Completion = { scope: str, mode: str, occurredAt: int, recordedAt: int }
  type Coverage = { scope: str, modes: Set[str], recordedAt: int }

  pure def completion(scope: str, mode: str, occurredAt: int, recordedAt: int): Completion =
    { scope: scope, mode: mode, occurredAt: occurredAt, recordedAt: recordedAt }

  pure def completions(index: int): List[Completion] = {
    val common = completion("current", "direct", 10, 10)
    if (index == 1) List(common)
    else if (index == 2) List(common.with("mode", "alternate"))
    else if (index == 3) List(completion("current", "direct", 9, 9))
    else if (index == 4) List(completion("current", "direct", 12, 12))
    else if (index == 5) List(completion("current", "direct", 11, 14))
    else if (index == 6) List(common.with("scope", "other occurrence"))
    else if (index == 7) List(common.with("scope", "other clock"))
    else if (index == 8) List(common, common)
    else if (index == 9) List(common.with("occurredAt", 11))
    else if (index == 10) List(common.with("scope", "other act"))
    else if (index == 11) List(completion("current", "direct", 8, 8))
    else if (index == 12) List(common.with("scope", "other definition"))
    else if (index == 13) List(common.with("scope", "other performer"))
    else List()
  }

  pure def coverageAt(index: int): Set[Coverage] = {
    val common = { scope: "current", modes: Set("direct", "alternate"), recordedAt: 12 }
    if (index == 0) Set()
    else if (index == 2 or index == 9) Set(common.with("modes", Set("direct")))
    else if (index == 3) Set(common.with("modes", Set("alternate")))
    else if (index == 4) Set(common.with("scope", "other occurrence"))
    else if (index == 5) Set(common.with("scope", "other clock"))
    else if (index == 6) Set(common.with("recordedAt", 11))
    else if (index == 7) Set(common.with("recordedAt", 16))
    else if (index == 8) Set(common.with("scope", "other clock version"))
    else if (index == 10) Set(common.with("scope", "other definition"))
    else if (index == 11) Set(common.with("scope", "other act"))
    else Set(common)
  }

  pure def omissionCase(time: int, reports: int, cover: int): int = {
    val effective = time / 3 + 8
    val cutoff = effective + (if (time % 3 == 0) 0 else if (time % 3 == 1) 1 else 4)
    val visible = completions(reports).select(report =>
      report.scope == "current" and report.recordedAt <= cutoff)
    val malformed = visible.select(report => report.recordedAt < report.occurredAt)
    val performed = visible.select(report =>
      9 <= report.occurredAt and report.occurredAt < 12 and report.occurredAt <= effective)
    val complete = coverageAt(cover).exists(coverage =>
      coverage.scope == "current" and coverage.recordedAt >= 12 and coverage.recordedAt <= cutoff
        and Set("direct", "alternate").subseteq(coverage.modes))
    if (malformed.length() > 0) 0
    else if (performed.length() > 0) 1
    else if (effective < 12) 2
    else if (complete) 4
    else 3
  }

  run omissionCoverageTest = assert(and {
    omissionCase(12, 0, 0) == 3, omissionCase(12, 0, 1) == 4,
    Set(2,3,4,5,6,7,8,9,10,11).forall(c => omissionCase(12, 0, c) == 3),
    omissionCase(11, 0, 1) == 2,
    Set(1,2,3,8).forall(r => omissionCase(12, r, 1) == 1),
    Set(4,5,6,7,10,11,12,13).forall(r => omissionCase(12, r, 1) == 4),
    omissionCase(14, 5, 1) == 1, omissionCase(8, 5, 1) == 2,
    omissionCase(12, 9, 1) == 0,
  })
}
