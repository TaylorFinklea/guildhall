# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 → 07-03 (Opus exec session #2 / #2b / #2c / #2d — reserve-claude fleet dispatch)

- **19 beads closed this session, all verified-by-artifact, 0 failed** (fleet → **54 closed**):
  - #2 (13): provenance-m3, bursar-m1, gauntlet-m2, warden-6xk/m4/m6, hindsight-m3, conductor-m0c/cov1/m3b/m4b/agy/nse.
  - #2b (1 + bug fix): gauntlet-m3-harvest (Sonnet, 6 golden tasks); conductor-guildhall-dogfood objective proof **+ fixed a silent-failure bug** (f21c2c2, bd.rs dependencies type) — still OPEN for the human dashboard eyeball; filed conductor-h23.
  - #2c+#2d senior wave (5, gpt-5.5, all verified): conductor-m4c (L keystone), bursar-m4, hindsight-m4, hindsight-m5 (+greened hindsight clippy gate), provenance-m4 (L).
- Routing: senior → external fleet via direct `pi` (zero Claude tokens); lead-floor (warden-m6, gauntlet-m3, guildhall-dogfood) → Sonnet. Every close verify-by-artifact; L-items adversarially checked by Opus. Detail in bd close reasons + `~/.claude` scorecard (exec #2/#2b/#2c/#2d) + git.

## Build Status

- All member repos green at their verify_cmds; **conductor + hindsight repo clippy gates now GREEN** (conductor-nse, hindsight-m5). bursar clippy green. Latent clippy debt likely still in provenance/gauntlet/warden (per-bead cargo-test never runs clippy — see scorecard).
- No source workers in flight. Logs → `~/.claude/model-bench.jsonl` (186 rows) + scorecard (exec #2–#2d).

## Blockers — FULL EXTERNAL FLEET DOWN

- **gpt-5.5 (openai-codex)**: 5h limit — re-tripped again ~2026-07-03 13:xxZ after the last 2 seniors. Pattern: ~3 heavy items per 5h window, then ~5h to reset.
- **opencode-go (qwen/glm/minimax)**: WEEKLY limit → resets ~2026-07-05.
- **agy (gemini-3.5-flash)**: quota-dead until ~2026-07-06.
- ⇒ Only Claude (Sonnet/Opus) is available right now. The senior fleet-dispatch wave is COMPLETE — remaining items are a fresh wave (below).

## Resume plan (next) — fresh wave, needs a routing decision

1. **`conductor-review` (P1, senior-floor L) — GATES v1.** Fleet-eligible but fleet is down; either Sonnet now or wait for fleet reset. Highest-value remaining item.
2. **Newly ready seniors** (fleet on reset, or Sonnet): `conductor-m5`, `conductor-m6`, `conductor-bursar`, `provenance-m5` (query.rs), `gauntlet-m4-replay-verify-judge` (L), `hindsight-m4-fixtures-hardening` (P3). `conductor-h23` (scan.rs silent-parse hardening).
3. **Human-verify tails (impls done, NON-gating)**: conductor-guildhall-dogfood dashboard eyeball → then human `bd close`; conductor-m3b live render; hindsight-m3 dashboard eyeball; bursar-m1/m4 seven_day live-Keychain smoke.
4. **HELD**: `envoy-e2e-dryrun` (needs the envoy SKILL run in a Claude harness — Sonnet/human dogfood, not a pi worker).
5. **Human TODOs**: drop 2 superseded stashes (provenance-m2 + hindsight-m2-pi-parser — classifier blocks agent stash-drop); install warden-m4 adapter into ~/.claude (chezmoi, warden HANDOFF-install.md); session-key rotation; chezmoi installs; tiers.md patch.

## Notes / landmines

- Dispatch harness lives in ephemeral `/tmp` scratchpad — does NOT survive a session interruption (a /login wiped it mid-run; reconstructed from history, no work lost). For long multi-wave runs keep prompts/helper durable.
- gpt-5.5 senior beads MUST run strictly serial (1 background job at a time) — parallel/late-session background jobs got intermittently killed (scorecard exec #2c).
