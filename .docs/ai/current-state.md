# Current State

> Updated at the end of every work session. Read this first.

## Active Branch
`main` (every member repo; all local, nothing pushed).

## In flight — 2026-07-08 Fable day #3 (MID-SESSION, background work running)
- **qxi dispatching** (bg `btc2xcw0k` → ollama-cloud/minimax-m3): path-granular integrity watch. E2E runs 5+6 BOTH false-positive integrity aborts (dispatch=pass verify=pass, aborted): run5 = orchestrator `.docs/ai` commit to guildhall; run6 = **USER OpenWiki concurrent write** to guildhall. `gauntlet-m4` now dep-blocked-by `gauntlet-qxi`.
- Next: qxi verify (confirm sr7 escape-detection preserved) → rebuild gauntlet → **E2E run 7** (guildhall drops OUT of watch for conductor-m2b → immune to OpenWiki) → close m4 + qxi.
- Then dispatch **conductor-m6** → minimax-m3 (senior/M ratchet; user-approved; must NOT overlap run 7 — m6 worker commits harness-conductor). Verify `cargo test ratchet`.

## Blockers / caveats
- guildhall has USER's live OpenWiki work UNCOMMITTED (`M AGENTS.md`, `?? openwiki/`) — **DO NOT touch/commit**. one-writer-per-repo: hold guildhall doc writes until quiet.
- `conductor-xa5` (NEW cutover blocker): `conductor dispatch` blanket-approval fires ALL 103 proposals (whole ~/git scan) — no per-item scoping. `conductor-ilv` dep-blocked-by xa5. Shadow session 3 = **NO-MATCH (reset 0/3)**.

## Build Status
- gauntlet b27b009: 110/0 (pre-qxi). conductor 6fa9158: 202/0 clippy-green. Others unchanged from 07-08 prior session.

## Resume plan
1. Check bg `btc2xcw0k` (qxi log ai-scratch/dispatch-qxi.log) → verify → rebuild → run 7 → close m4+qxi.
2. Dispatch+verify+close `conductor-m6` (minimax-m3, prompt in scratchpad dispatch-conductor-m6.md).
3. Guildhall handoff docs (roadmap ticks) + harness-deck report once guildhall quiet.
