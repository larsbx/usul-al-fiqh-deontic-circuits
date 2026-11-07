// Candidate K1 extension. Actor-specific solo permission leaves the two
// revocation profiles and the mixed-knowledge candidate composition intact.
module agencyMask {
  import agency.* from "./agency"

  pure def maskTransition(configCode: int, s: State, e: Event): Transition = {
    val mask = configCode % 4
    val solo = match e {
      | ExecuteA => mask % 2 == 1
      | ExecuteB => mask / 2 == 1
      | _ => false
    }
    val profile = if (configCode < 4) Immediate else OnKnowledge
    transition({ profile: profile, independent: solo }, s, e)
  }

  pure def maskNextCode(configCode: int, stateCode: int, eventCode: int): int =
    match maskTransition(configCode, decodeState(stateCode), decodeEvent(eventCode)) {
      | Disabled => -1
      | Enabled(nextState) => encodeState(nextState)
    }

  pure def attempts(configCode: int, events: List[int]): List[int] =
    events.foldl((0, List()), (acc, event) => {
      val nextState = maskNextCode(configCode, acc._1, event)
      (if (nextState < 0) acc._1 else nextState, acc._2.append(nextState))
    })._2

  run singletonGrantsTest = assert(and {
    attempts(5, List(0, 7, 6)) == List(1, -1, 65),
    attempts(6, List(0, 6, 7)) == List(1, -1, 129),
    attempts(5, List(0, 8)) == List(1, 193),
    attempts(6, List(0, 8)) == List(1, 193),
  })

  run withdrawalTest = assert(and {
    attempts(5, List(0, 4, 8, 6, 7)) == List(1, 17, -1, -1, -1),
    attempts(6, List(0, 5, 8, 7, 6)) == List(1, 33, -1, -1, -1),
    attempts(5, List(0, 5, 8, 6)) == List(1, 33, -1, 97),
    attempts(6, List(0, 4, 8, 7)) == List(1, 17, -1, 145),
  })

  run knowledgeTest = assert(and {
    attempts(5, List(0, 1, 2, 8, 6, 7)) == List(1, 3, 7, -1, -1, -1),
    attempts(6, List(0, 1, 3, 8, 7, 6)) == List(1, 3, 11, -1, -1, -1),
    attempts(5, List(0, 1, 3, 8, 6)) == List(1, 3, 11, -1, 75),
    attempts(6, List(0, 1, 2, 8, 7)) == List(1, 3, 7, -1, 135),
    attempts(1, List(0, 1, 6)) == List(1, 3, -1),
    attempts(2, List(0, 1, 7)) == List(1, 3, -1),
  })
}
