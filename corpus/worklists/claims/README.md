# Shard claims

One `<shard>.json` per shard of a parallel run, written before the shard starts. The format and rules are in [`docs/architecture/derivation-method.md` §5](../../../docs/architecture/derivation-method.md#5-parallel-runs):

```json
{"shard": "rajab-t11-a", "lane": "A", "base_commit": "<full 40-hex sha>", "obligations": ["ibn_rajab.taqrir_qawaid.openiti_rajab_shamela21730.q013.f000", "…"]}
```

`test_committed_shard_state_is_consistent` rejects:
- a base commit that is not a full sha;
- an obligation that is not pending in a generated worklist;
- an obligation that two shards both claim.

The integrator removes a shard's claim when it merges the shard.
