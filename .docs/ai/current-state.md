# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus execution session #1 — first real dispatch cycle)

- **9 beads closed, verified-by-artifact, 0 failed verifies** (fleet total 22 → **31 closed**):
  warden-rev (LEAD, Opus), warden-m3, provenance-seam (LEAD, Sonnet), gauntlet-m0, gauntlet-m1,
  conductor-m4a, conductor-m3a, bursar-m2-codex, bursar-m3-agy.
- Routing: Opus only for warden-rev (security core); Sonnet for provenance-seam; **7 gpt-5.5** senior impl. No 429s.
- warden-rev: policy core faithful, all 8 invariants hold; pinned invariant-3 session-op/headless adapter contract (test); filed **warden-6xk** (classifier heuristic hardening: dd of=/dev, symlink WriteInRepo).
- Broken clippy gates found (per-bead `cargo test X` verify_cmds don't run clippy → drift): warden config.rs **FIXED** (15130d3); conductor filed **conductor-nse** (4 lints in bd/config/triage).
- Dispatch logs appended to `~/.claude/model-bench.jsonl` + scorecard Experience Log (append-only ledgers; chezmoi drift is human-reconciled, not config writes).

## Build Status

- warden 43 tests + clippy green; gauntlet 18; conductor `cargo test` green (repo clippy red → conductor-nse); bursar tests + clippy green; provenance fixture jq-valid.
- **Stashes STILL PENDING** (held, not rushed at close-cap): provenance stash (m2 store.rs partial — pop + build);
  hindsight stash (m2-pi partial — **ORPHAN-FILE landmine**: fold into committed `src/sources/pi.rs`, NOT a naive pop).

## Blockers

- Provider limits: check LIVE at session start. agy quota-dead until ~2026-07-06 (parked).

## Resume plan (next session)

1. **Stash-redo beads FIRST, carefully**: provenance-m2 (pop + build), hindsight-m2-pi-parser (orphan-fold into pi.rs — Opus/lead should drive the fold, not a blind worker).
2. Then `bd ready` per member: bursar-m1-anthropic; conductor m1c/m0c/agy/cov1 + conductor-nse; warden m5/m6 + warden-6xk; gauntlet-m2 (human-verify tail); envoy-e2e-dryrun (dogfood — poor headless fit, drive by hand).
3. `conductor-review` still gates v1 (unblocks after m4b/m4c). foreman ×6 still deferred; conductor-warden v1.5.
4. Honor caps; verify-by-artifact; log every non-default dispatch; harness-deck checkpoint ~every 8.
