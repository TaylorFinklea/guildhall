# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus execution session #1 — first dispatch cycle, continued)

- **11 beads closed, verified-by-artifact, 0 failed verifies** (fleet 22 → **33 closed**):
  first burst (9): warden-rev, warden-m3, provenance-seam, gauntlet-m0/m1, conductor-m4a/m3a, bursar-m2-codex/m3-agy;
  then both stash landmines — **hindsight-m2-pi-parser** (orphan folded into pi.rs; 80 tests) + **provenance-m2** (fresh store.rs; glm).
- **gpt-5.5 (openai-codex) hit its 5h usage limit** mid-session → HELD (no retry, per runbook). Fell back: glm-5.2 (provenance-m2), Sonnet (hindsight fold + provenance-seam). minimax-m3 + qwen3.7-max also confirmed alive.
- Routing: Opus only for warden-rev; Sonnet for LEAD-floor + the landmine fold; pi (gpt-5.5/glm/minimax) for senior impl.
- Both stashes now SUPERSEDED (hindsight folded; provenance was a trivial 1-line `mod store;`) — safe for a HUMAN to drop; agent `git stash drop` was blocked by the safety classifier.
- Filed: warden-6xk (classifier heuristic hardening), conductor-nse (4 pre-existing clippy lints). warden config.rs clippy-gate fix landed.

## Build Status

- warden 43 + clippy green; hindsight 80 tests; gauntlet 18; conductor `cargo test` green (repo clippy red → conductor-nse); bursar + provenance tests + clippy green.
- IN FLIGHT (2 workers): conductor-m1c (glm-5.2), warden-m5 agy-interception doc (minimax-m3).
- Dispatch logs → `~/.claude/model-bench.jsonl` + scorecard Experience Log (append-only ledgers; chezmoi drift is human-reconciled).

## Blockers

- **gpt-5.5 (openai-codex) HELD** — hit 5h usage limit ~2026-07-02 ~14:5x UTC; check live before re-dispatching. opencode-go (glm/minimax/qwen) OK. agy quota-dead until ~2026-07-06.

## Resume plan (next)

1. Verify + close the 2 in-flight (conductor-m1c, warden-m5).
2. Then `bd ready` per member (opencode-go / Sonnet while gpt-5.5 held): warden-m6 (**LEAD-floor → Sonnet**) + warden-6xk; conductor m0c/agy/cov1 + conductor-nse; bursar-m1-anthropic (live endpoint — fragile); provenance-m4 (correlate); gauntlet-m2 + hindsight-m3 (both **human-verify tails** — drive by hand); envoy-e2e-dryrun (dogfood — drive by hand).
3. `conductor-review` still gates v1 (after m4b/m4c). foreman ×6 deferred; conductor-warden v1.5.
4. Human: drop the 2 superseded stashes (provenance, hindsight). Honor caps; verify-by-artifact; log every non-default dispatch.
