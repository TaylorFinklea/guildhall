# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus execution session #1 — first dispatch cycle)

- **13 beads closed, verified-by-artifact, 0 failed verifies** (fleet 22 → **35 closed**):
  warden-rev, warden-m3, warden-m5, provenance-seam, provenance-m2, gauntlet-m0, gauntlet-m1,
  conductor-m4a, conductor-m3a, conductor-m1c, bursar-m2-codex, bursar-m3-agy, hindsight-m2-pi-parser.
- Both stash landmines resolved: **hindsight-m2-pi-parser** (757-line orphan folded into pi.rs; 80 tests) + **provenance-m2** (fresh store.rs; the "partial" was a trivial 1-liner).
- **Provider events**: gpt-5.5 (openai-codex) hit its 5h usage limit → HELD. glm-5.2 had ONE silent no-op (conductor-m1c; caught by verify-by-artifact, retried on qwen3.7-max → clean). minimax + qwen + glm otherwise solid.
- Routing: Opus only for warden-rev; Sonnet for LEAD-floor + the landmine fold; pi (gpt-5.5/glm/minimax/qwen) for senior impl/doc.
- Stashes SUPERSEDED (both) — safe for a HUMAN to drop (agent `git stash drop` blocked by safety classifier).
- Filed: warden-6xk (classifier hardening); conductor-nse (repo clippy gate — now covers bd/config/triage PRE-existing + cli.rs lints qwen added on m1c). warden config.rs clippy fix landed.

## Build Status

- warden 43 + clippy green; hindsight 80; gauntlet 18; conductor `cargo test` green (repo clippy red → conductor-nse); bursar + provenance green.
- No workers in flight. Dispatch logs → `~/.claude/model-bench.jsonl` (150 rows) + scorecard Experience Log (append-only; chezmoi drift human-reconciled).

## Blockers

- **gpt-5.5 (openai-codex) HELD** — hit 5h usage limit ~2026-07-02 ~14:5x UTC; check live before re-dispatching. opencode-go (glm/minimax/qwen) OK. agy quota-dead until ~2026-07-06.

## Resume plan (next)

1. `bd ready` per member (opencode-go / Sonnet while gpt-5.5 held). Remaining are mostly NOT plain-clean:
   - **LEAD-floor → Sonnet/Opus**: warden-m6 (dispatch-surface-coverage doc).
   - **Human-verify tails (drive by hand, not headless)**: gauntlet-m2 (manual dry-run), hindsight-m3 (hdeck validate + eyeball), bursar-m4-cli, provenance-m5.
   - **Fragile**: bursar-m1-anthropic (live oauth endpoint). **Dogfood/poor headless fit**: envoy-e2e-dryrun.
   - **Clean-ish senior (pi ok)**: warden-6xk, conductor m0c/agy/cov1 + conductor-nse, provenance-m4 (correlate).
2. `conductor-review` still gates v1 (after m4b/m4c). foreman ×6 deferred; conductor-warden v1.5.
3. Human TODOs: drop the 2 superseded stashes (provenance, hindsight); the pending-human items from the handoff (session-key rotation, chezmoi installs, tiers.md patch) remain.
4. Honor caps; verify-by-artifact (exit codes lied once this session — glm no-op); log every non-default dispatch.
