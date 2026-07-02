# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 (Opus exec session #2 + #2b)

- **exec #2 — 13 beads closed, verified-by-artifact, 0 failed** (fleet 33 → 48): provenance-m3, bursar-m1, gauntlet-m2, warden-6xk/m4/m6, hindsight-m3, conductor-m0c/cov1/m3b/m4b/agy/nse. Reserve-claude dispatch: 12 senior → external fleet via direct `pi` (zero Claude tokens), warden-m6 (lead) → Sonnet. Details in bd close reasons + scorecard exec #2 + git.
- **exec #2b — 2 lead-floor items on Sonnet** (fleet is below the lead floor):
  - **gauntlet-m3-harvest** CLOSED (7091425): 6 golden tasks harvested via hindsight's claude_code parser (used, not forked); all smoke-run ok; no leaked worktrees. (fleet → **49**)
  - **conductor-guildhall-dogfood** — objective proof DONE + it **found & fixed a silent-failure bug** (f21c2c2: `Issue.dependencies` typed `Vec<String>` vs real bd-ready edge-objects → `unwrap_or_default` silently emptied 6/8 repos' ready lists; Ready 112→281). 7-bead/6-repo triage spot-check all matched; tier_floor gate honored. **NOT closed** — human dashboard-render eyeball tail remains (see bd comment). Filed **conductor-h23** for the root silent-swallow gap.
- **FLEET OUTAGE mid-#2b**: the 4 wave-2 senior dispatches 429'd instantly (opencode-go WEEKLY limit + gpt-5.5 5h) — zero work, repos clean (verify-by-artifact). User chose to PAUSE the 5 senior beads pending gpt-5.5's 5h reset.

## Build Status

- All member repos green. harness-conductor at **f21c2c2** (`cargo test` 146 + `cargo clippy --all-targets -D warnings` green). gauntlet +6 golden tasks (smoke-run ok). No source workers in flight.
- Logs → `~/.claude/model-bench.jsonl` (165 rows) + scorecard Experience Log (exec #2 + #2b).

## Blockers — FULL EXTERNAL FLEET DOWN

- **opencode-go (qwen/glm/minimax)**: WEEKLY limit hit ~2026-07-02 20:14 → resets ~2026-07-05. All 3 models share the one workspace quota.
- **gpt-5.5 (openai-codex)**: 5h limit → poller `b2duh2b9u` armed to auto-resume the paused senior wave on reset (~hours).
- **agy (gemini-3.5-flash)**: quota-dead until ~2026-07-06.

## Resume plan (next)

1. **PAUSED senior wave — resume on gpt-5.5 when its 5h resets** (poller re-wakes; or opencode-go ~07-05): `conductor-m4c` (L), `provenance-m4` (L), `hindsight-m4-guardian-agy` (M) → then `hindsight-m5-hd-beads-sources` (M, same repo serial), `bursar-m4-cli` (S, has non-gating live-Keychain human tail). Prompts staged in scratchpad/prompts. Pace gpt-5.5 (it re-tripped after 3 heavy items).
2. **Human-verify tails (impls done, NON-gating)**: conductor-guildhall-dogfood dashboard-render eyeball (then human `bd close`); conductor-m3b live report render; hindsight-m3 dashboard eyeball; bursar-m1 seven_day live smoke.
3. **HELD (poor headless fit)**: `envoy-e2e-dryrun` — needs the envoy SKILL run in a Claude harness (dogfood) + validate-envelope.sh.
4. **New senior bead**: `conductor-h23` (scan.rs — surface bd-ready parse failures instead of silently emptying a repo).
5. **Human TODOs carried**: drop the 2 superseded stashes (provenance-m2 + hindsight-m2-pi-parser — safety classifier blocks agent stash-drop); install warden-m4 adapter into ~/.claude (chezmoi, see warden HANDOFF-install.md); session-key rotation; chezmoi installs; tiers.md patch.
