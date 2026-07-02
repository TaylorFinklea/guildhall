# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus exec session #2 — opencode-go + gpt-5.5 reserve-claude dispatch)

- **13 beads closed, verified-by-artifact, 0 failed** (fleet 35 → **48 closed**):
  provenance-m3, bursar-m1, gauntlet-m2, warden-6xk, warden-m4, warden-m6, hindsight-m3,
  conductor-m0c / cov1 / m3b / m4b / agy / nse.
- **Routing (reserve-claude)**: 12 senior beads → EXTERNAL fleet via direct `pi --model X --approve -p @prompt </dev/null` (ZERO Claude tokens for impl); warden-m6 (`tier_floor:lead`) → Sonnet subagent (fleet below floor). Per-repo SERIAL (git-index race), cross-repo parallel. Every close verified-by-artifact (re-ran exact verify_cmd + confirmed real commit); the 2 L-items (conductor-m4b, gauntlet-m2) adversarially confirmed by Opus self-review.
- **Provider events**: gpt-5.5 (openai-codex) BACK (5h limit reset) — owned the 3 hardest (conductor-m4b L, gauntlet-m2 L, warden-m4), no timeout. agy quota-dead until ~2026-07-06 (off roster; junior→seniors). opencode-go (qwen/glm/minimax) solid; NO silent no-ops this wave.
- **2 reliability events, both caught by verify-by-artifact, neither a quality miss**: (a) hindsight-m3 glm completed impl but hit the 20-min per-dispatch timeout (rc=124) PRE-commit → Opus verified dirty tree (34 tests, additive-only parser edits) + finalized commit; (b) conductor 6-bead SERIAL background job KILLED at ~36min (background-job lifetime) mid-nse with 5/6 already committed → verified the 5 + re-dispatched nse standalone. LESSONS (scorecard): cap serial tracks ~4 beads / size big-M as L / raise per-bead timeout.

## Build Status

- All member repos green at their verify_cmds. conductor: `cargo test` 146 + `cargo clippy --all-targets -- -D warnings` **NOW GREEN** (conductor-nse). warden 14 classify + adapter_claude 3 / provenance 34 / hindsight 34 / gauntlet 25 / bursar 39 + clippy.
- No workers in flight. Logs → `~/.claude/model-bench.jsonl` (163 rows) + scorecard Experience Log (exec #2 section).

## Blockers

- agy (gemini-3.5-flash High) quota-dead until ~2026-07-06. gpt-5.5 + opencode-go OK.

## Resume plan (next)

1. `bd -C ~/git/<member> ready`. Newly UNBLOCKED by exec #2 (all deps landed + verified): `conductor-m4c` → `conductor-review` (P1, gates v1) → `conductor-guildhall-dogfood`; `provenance-m4` (correlate); `gauntlet-m3-harvest`; `hindsight-m4`/`m5`; `bursar-m4-cli`.
2. **HELD (poor headless fit)**: `envoy-e2e-dryrun` — needs the envoy SKILL actually run in a Claude harness against a real repo (dogfood) + `validate-envelope.sh`; do with Sonnet/human, NOT a pi worker.
3. **Human-verify tails (non-gating; impls DONE)**: conductor-m3b live report render, hindsight-m3 dashboard eyeball, bursar-m1 seven_day_sonnet/opus live smoke.
4. **Human TODOs carried**: drop the 2 superseded stashes (provenance-m2 + hindsight-m2-pi-parser — safety classifier blocks agent stash-drop); install warden-m4 adapter into ~/.claude (chezmoi, see warden docs/HANDOFF-install.md); session-key rotation; chezmoi installs; tiers.md patch.
5. Honor verify-by-artifact + per-dispatch timeouts; cap serial tracks; log every non-default dispatch.
