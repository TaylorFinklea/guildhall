# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main`

## Last Session Summary

**Date**: 2026-07-01

- Guildhall chartered + all 8 repos specced/backlogged (44 member beads); user approved dispatch; fleet build underway.
- **Done + verified** (orchestrator re-ran each verify_cmd): envoy = validator + consult-prompt + skill + handoff-install (only envoy-e2e-dryrun left); warden-m0; hindsight m0 + m1 (claude-code parser); bursar/provenance/gauntlet/foreman = specced, not started.
- Conductor (separate track): cycle 1 implementation COMPLETE 8/8 (triage core m2b passed all 9 named invariant tests). conductor-rev1 lead review PENDING (see Blockers).

## Build Status

- envoy: validator/consult-prompt/skill/handoff all green. warden: M0 green (11 tests). hindsight: M0+M1 green (build+parser). All local, unpushed.
- **warden CAVEAT**: warden-m1 (classify port) is INCOMPLETE — a killed sonnet worker amended a PARTIAL classify.rs (~110 lines, 2 tests) into the warden-m0 commit (6bf2100, mislabeled). warden-m1 is released/open; redo must COMPLETE the port + full guardian test suite + unknown-tool-gated test and make a proper separate `warden-m1:` commit (do not reset; extend). See warden-m1 bd comments.

## Blockers — FLEET-WIDE RATE LIMIT (2026-07-01 ~19:40 local)

- **opencode-go** (glm/minimax/qwen via pi): 5-hour limit hit, resets ~2hr (~21:45 local). glm→bursar-m0 and qwen→warden-m1 both 429'd, no work, released.
- **Anthropic** (Fable main loop + Claude sonnet/opus subagents): session limit, resets ~9:10pm America/Chicago. Killed opus→conductor-rev1 (unstarted, released) and sonnet→warden-m1 (partial, see caveat).
- **agy** (gemini-3.5-flash): quota-exhausted until ~2026-07-06.
- **openai-codex** (gpt-5.5): last backend not confirmed limited — use sparingly on resume.

## Resume plan (next session, once capacity returns)

1. Ready senior/junior beads (pi-capable): warden-m1 (redo, note the partial state), bursar-m0, hindsight-m2 (codex+pi parsers), envoy-e2e-dryrun, provenance-m0/seam/m1, gauntlet-m0. Build order: warden→hindsight→(envoy finish)→bursar→provenance→gauntlet→foreman.
2. **Lead-floor beads — need a Claude lead (opus/sonnet-5), NOT a senior pi model**: conductor-rev1 (adversarial review of the triage core — released, unstarted), warden-rev, gauntlet-m3 (harvest) + m6 (efficiency), foreman-prompt.
3. Every close gated on orchestrator re-running the bead's verify_cmd. Log each dispatch to ~/.claude/model-bench.jsonl + scorecard.
4. Standing: gemini-flash parked till ~07-06; rotate the plaintext claude.ai session-key in ~/.claude/fetch-claude-usage.swift (human).

## Score this session

15 beads verified+closed (7 conductor cycle-1 impl + m2b + 7 guildhall: envoy×4, warden-m0, hindsight×2), 0 failed verifies, 1 below-floor dispatch caught by the tier gate, 1 partial-worker recovery, 2 clean rate-limit releases.
