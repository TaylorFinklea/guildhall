# Current State

> Updated at the end of every work session. Read this first.

## Active Branch
`main` (every member repo; all local, nothing pushed).

## Last Session Summary
**Date**: 2026-07-09 (v1 finish + product demo — spec/plan in `phases/v1-finish-demo-{spec,plan}.md`)
- **OpenWiki ADOPTED** (c4b38bf): `openwiki/` + softened AGENTS.md pointer + user's ADR committed; orientation-only, never source-of-truth. `conductor-1qh` reconciled/closed.
- **`gauntlet-m5` CLOSED** (8c37580, gpt-5.5): ab.rs + deck.rs + `run --config-delta`. Routing corrected mid-flight (m5 is **L**, above minimax's M ceiling). Orchestrator re-verified 118/0 + clippy + hdeck-valid report; worker honored cost-control (fake exec, **no quota**). Honest note: 1 transient test failure on first verify, unreproducible in 21+ runs, no latent race on review.
- **`demo/` SHIPPED** (3fec3aa): `demo/run.sh [all|<member>]` drives all 8 members on real substrate, read-only, **no metered dispatch**, honest maturity labels (live / dry-run / spec-only). Conductor step = the v1 integration proof.
- **`gauntlet-nfx` FILED (P1, lead)**: `gauntlet lint` → **6/6 golden tasks defective** (verify_cmd passes at base ⇒ can't discriminate fix from no-op). **Blocks `gauntlet-m6`** — user decision: fix the harvest before patching `tiers.md`. m6 is gauntlet's final v1 milestone.

## Blockers / caveats
- guildhall has USER's uncommitted `openwiki/{_plan,operations,workflows}.md` edits (their tooling, post-adoption) — **DO NOT touch**; keep guildhall doc commits surgical (explicit paths).
- `conductor-xa5` (cutover blocker) + shadow streak 0/3 still gate `conductor dispatch` as default loop. Roster-router chain + `conductor-m5` un-defer **07-10**.
- Foreman honored-deferred to 2026-08 per ADR (demo shows it honestly as spec-only).

## Build Status
- gauntlet 8c37580: 118/0 clippy-green. conductor 6698534: 228/0 clippy-green. hindsight/provenance/bursar/warden CLIs built (demo). Others unchanged.

## Resume plan
1. `bd prime`. Ready: `gauntlet-nfx` (P1, lead — repair golden-task verify_cmds so lint exits 0) → then unblocks `gauntlet-m6`.
2. Roster-router chain + `conductor-m5` un-defer 07-10; `conductor-xa5` (lead) still open.
3. Try the demo: `demo/run.sh` (or `demo/run.sh <member>`).
