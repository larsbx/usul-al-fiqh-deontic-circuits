module idaPremiseIngestion {
  pure def admission(mode: int): int = {
    val expected = List(1, 2, 3, 4)
    val tokens = if (mode == 6) List(1, 2, 3, 3)
      else if (mode == 8) List(1, 2) else expected
    val sources = if (mode == 1) Set(1) else Set(1, 2)
    val grants = if (mode == 2) Set(1) else Set(1, 2)
    val currentSnapshot = if (mode == 3) 3 else 2
    val premiseProfile = if (mode == 4) 2 else 1
    val premiseInquiry = if (mode == 5) 2 else 1
    val versions = if (mode == 7) Set() else Set(1)
    if (tokens.indices().exists(i => tokens.indices().exists(j => i < j and tokens[i] == tokens[j]))) 3
    else if (tokens != expected) 1
    else if (not(tokens.indices().forall(i => sources.contains(2 - tokens[i] % 2)))) 2
    else if (currentSnapshot != 2) 5
    else if (premiseProfile != 1 or premiseInquiry != 1) 6
    else if (not(versions.contains(1))) 7
    else if (not(grants.contains(2))) 4
    else 0
  }

  var results: List[int]
  action init = results' = 0.to(8).fold(List(), (rows, mode) => rows.append(admission(mode)))
  action step = results' = results
}
