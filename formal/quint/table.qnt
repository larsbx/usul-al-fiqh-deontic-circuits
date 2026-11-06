// A deterministic evaluation of every one-step input, not sampled exploration.
// The CLI's single zero-step trace serializes this entire vector in ITF JSON.
module table {
  import agency.nextCode from "./agency"

  var transitions: List[int]

  action init = transitions' = range(0, 4 * 256 * 13).foldl(List(), (rows, index) =>
    rows.append(nextCode(index / (256 * 13), (index / 13) % 256, index % 13)))
  action step = transitions' = transitions
}
