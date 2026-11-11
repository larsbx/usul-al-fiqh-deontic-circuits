# scripts.CheckIDAPremiseIngestion in Plain English

Source: [`formal/lean/scripts/CheckIDAPremiseIngestion.lean`](../../../formal/lean/scripts/CheckIDAPremiseIngestion.lean)

The runner reads the revision, source references and certificate tokens
from the host, then returns the typed pilot's outcome. In controls mode it
emits the nine Lean outcomes for comparison with Quint. The runner relies
on the host to authenticate its inputs.
