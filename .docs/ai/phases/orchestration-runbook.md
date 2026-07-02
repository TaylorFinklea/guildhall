# Fleet orchestration runbook — how to be the master of works

**Status**: operational handoff (Fable 5 → Opus, 2026-07-02). This is the
distilled how-to from the first real orchestration session (32+ dispatches,
23 beads verified-closed, zero failed verifies, 3 provider-limit events, 2
worker-crash recoveries). Conductor will eventually automate this loop; until
its M4 ships, the Lead session IS Conductor. Everything here is
execution-proven, not theoretical.

## The loop (per bead)

1. **Pick**: `bd -C <repo> ready --json` — honor the build order (charter §
   Build order) and `tier_floor` in metadata. READ the bead's real floor
   before routing; a below-floor dispatch was nearly made once (envoy
   consult-prompt, lead-floor, almost went to a senior) — the gate works only
   if you check it.
2. **Claim**: `bd -C <repo> --actor <model> update <id> --claim < /dev/null`.
   Re-claim after a release needs `update <id> --assignee "<model>"` (claim
   errors if already claimed).
