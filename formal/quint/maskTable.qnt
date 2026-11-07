// Single deterministic export of every candidate mask input.
module maskTable {
  import agencyMask.maskNextCode from "./agencyMask"

  var transitions: List[int]

  action init = transitions' = range(0, 8 * 256 * 13).foldl(List(), (rows, index) =>
    rows.append(maskNextCode(index / (256 * 13), (index / 13) % 256, index % 13)))
  action step = transitions' = transitions
}
