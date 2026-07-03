# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus exec session #2 / #2b / #2c — reserve-claude fleet dispatch)

- **17 beads closed this session, all verified-by-artifact, 0 failed** (fleet → **52 closed**):
  - #2 (13): provenance-m3, bursar-m1, gauntlet-m2, warden-6xk/m4/m6, hindsight-m3, conductor-m0c/cov1/m3b/m4b/agy/nse.
  - #2b (1 + a bug fix): gauntlet-m3-harvest (Sonnet, 6 golden tasks); conductor-guildhall-dogfood objective proof + **fixed a silent-failure bug** (f21c2c2, bd.rs dependencies type) — OPEN pending human dashboard eyeball; filed conductor-h23.
  - #2c (3, gpt-5.5): conductor-m4c (L keystone — unblocks conductor-review/v1), bursar-m4, hindsight-m4.
- Routing: senior beads → external fleet via direct `pi` (zero Claude tokens); lead-floor (warden-m6, gauntlet-m3, guildhall-dogfood) → Sonnet. Verify-by-artifact every close; L-items adversarially checked by Opus.
- Detail lives in bd close reasons + `~/.claude` scorecard (exec #2/#2b/#2c) + git.

## Build Status

- harness-conductor **6754ad6** (test 149 green; **clippy green**). bursar **db7fbfd** (test+clippy green). hindsight **164d06c** (test 103+34 green; **clippy RED ~11 lints — pending hindsight-m5's whole-repo pass**, mostly pre-existing recap.rs from m3). gauntlet 7091425 (+6 golden tasks). warden/provenance green.
- Logs → `~/.claude/model-bench.jsonl` (184 rows) + scorecard (exec #2/#2b/#2c).

## Blockers — FULL EXTERNAL FLEET DOWN

- **gpt-5.5 (openai-codex)**: 5h limit — RE-TRIPPED ~2026-07-03 00:2xZ after 3 heavy items (m4c/bursar-m4/hindsight-m4). Poller re-armed for next reset (~hours). Pattern: it does ~3 heavy items per 5h window.
- **opencode-go (qwen/glm/minimax)**: WEEKLY limit → resets ~2026-07-05.
- **agy (gemini-3.5-flash)**: quota-dead until ~2026-07-06.

## Resume plan (next)

1. **2 senior beads still PAUSED — resume on gpt-5.5's next 5h reset** (poller re-wakes) or opencode-go weekly (~07-05): `hindsight-m5-hd-beads-sources` (M — MUST also green the repo clippy gate: ~11 lints in recap.rs/pi.rs/agy.rs, conductor-nse pattern; prompt staged) and `provenance-m4` (L, correlate.rs). Serial, 1 bg job at a time (see scorecard lesson on background-job kills).
2. **Newly UNBLOCKED by m4c**: `conductor-review` (P1, **gates v1**), `conductor-m5`, `conductor-m6`, `conductor-bursar`.
3. **Human-verify tails (impls done, NON-gating)**: conductor-guildhall-dogfood dashboard eyeball (then human `bd close`); conductor-m3b live render; hindsight-m3 dashboard eyeball; bursar-m1/m4 seven_day live-Keychain smoke.
4. **HELD**: `envoy-e2e-dryrun` (needs envoy SKILL run in a Claude harness). **New bead**: `conductor-h23` (scan.rs silent-parse). **Systemic**: latent clippy debt in provenance/gauntlet/warden/bursar (per-bead cargo-test never runs clippy) — consider a sweep.
5. **Human TODOs**: drop 2 superseded stashes (provenance-m2 + hindsight-m2-pi-parser — classifier blocks agent stash-drop); install warden-m4 adapter into ~/.claude (chezmoi); session-key rotation; chezmoi installs; tiers.md patch.
