# Current State

> Updated at the end of every work session. Read this first.

## Active Branch
`main` (every member repo; all local, nothing pushed).

## In flight — 2026-07-08 Fable day #3 (MID-SESSION, m6 worker running)
- **conductor-m6 dispatching** (bg `byr5etpcu` → ollama-cloud/minimax-m3): autonomy ratchet (ratchet.rs + junior/S config default per ADR). Verify `cargo test ratchet` + full suite + clippy. On pass → close m6, log scorecard.
- **gauntlet-m4 + gauntlet-qxi CLOSED** ✅. E2E run 8 (post-qxi) completed the full harvest set — NO integrity abort (qxi confirmed live where the user's OpenWiki aborted runs 5+6). E2E bug-hunt arc DONE: runs 1-8 caught+fixed 5 product bugs (sr7→43t→xqj→qgo→qxi). **gauntlet-m5 now unblocked.** qxi hardened by orchestrator (committed-escape sr7 gap; 0ad6667).

## Blockers / caveats
- guildhall has USER's live OpenWiki work UNCOMMITTED (`M AGENTS.md`, `?? openwiki/`) — **DO NOT touch/commit**. one-writer-per-repo: keep guildhall doc commits surgical (explicit paths only).
- `conductor-xa5` (NEW cutover blocker): `conductor dispatch` blanket-approval fires ALL 103 proposals (whole ~/git scan) — no per-item scoping. `conductor-ilv` dep-blocked-by xa5. Shadow session 3 = **NO-MATCH (0/3)**.
- E2E runs got killed once mid-dispatch (run 7, environmental — matches prior job-kill pattern); recovered by re-run (run 8). qxi/m6 pi dispatches unaffected.

## Build Status
- gauntlet 0ad6667: 113/0 clippy-green (qxi + committed-escape hardening). conductor 6fa9158: 202/0 clippy-green (m6 worker building on it).

## Resume plan
1. Check bg `byr5etpcu` (m6 log ai-scratch/dispatch-m6.log) → verify → close m6 → scorecard.
2. gauntlet-m5-ab-report now ready (P2) — next gauntlet milestone.
3. Roadmap ticks (m4 done) + harness-deck report once guildhall quiet.
