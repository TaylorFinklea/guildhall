# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-07 (Fable day #2 — orchestrated exec)

- **14 verified closes** (fleet → 69): conductor-fxo/bursar(V1-GATING)/h23/frv · warden-vy1 · provenance-ba9(no-op)/m5 · gauntlet-s7h/**sr7**(P1 sandbox)/**xqj**(120s-timeout root cause)/**43t**(read-ref allowlist) · hindsight-m4 · envoy-e2e(Sonnet). E2E runs 1–3 each caught a real defect (sandbox → refusal policy → timeout); `gauntlet-m4` unblocked, awaiting run-4 evidence. `gauntlet-7mi` still open.
- **User decisions (harness-deck) ACTED ON**: gpt-5.5 ceiling M→L (6ba5f91, drift none) · roster-router P1 this month, dep-blocked on 24e · lane policy: opencode-go+ollama-cloud primary, **NeuralWatt fallback-only** (bd memory `provider-lane-policy`).
- **OVERNIGHT E2E run 4 detached** (pid 33939, ≤240m wall, 12-dispatch cap, gpt-5.5 workers/qwen judges): `~/git/gauntlet/ai-scratch/e2e-run4.log`. Green pass-path → close gauntlet-m4.
- **Phase A: done except gauntlet-m4 E2E + human tails.** Shadow session 1 recorded on `conductor-ilv` (NO-MATCH 0/3; 4 mismatch classes; remediations landed). Roster-router spec split → 5 dep-chained beads (deferred 07-10).
- **11 beads filed** (review findings 24e/1s8/p9k, bursar-g0n, envoy-hii, frv ceiling, 5×roster-router). 2 ADRs `[2026-07-07]` (queue-encodes-plan; secrets-routing). Landmines memory +4 (unattended clause, whole-tree verify, opencode-go drops, pi-log recovery).
- **Lane news**: ollama-cloud/minimax 2/2 verified closes (scorecard bumped); opencode-go dropped 2 sessions mid-work (exit 0, no error); gpt-5.5 2 heavy closes + 1 scope-stray (reverted, preserved as d5j reference patch).

## Build Status

- conductor a94008a-era: 199/0 + 17 clippy warnings (sweep = p9k). gauntlet a94008a 41/0 clippy 0. provenance b049f07 58/0. hindsight e4cbdce 148/0. warden 6660e28 47/0 clippy 0. Ledger 232+ rows; scorecard Experience Log through 07-07.

## Blockers

- gauntlet-m4 close awaits overnight run-4 results (read e2e-run4.log first thing). Human tails (roadmap Now).

## Resume plan

1. `bd prime` per repo. **Read ~/git/gauntlet/ai-scratch/e2e-run4.log** — pass-path green → close gauntlet-m4 + tick roadmap; failures → each gets a bead (runs 1–3 pattern: every failure was a real product bug).
2. Fleet (lanes: opencode-go+ollama-cloud primary, NeuralWatt fallback-only): conductor-24e (unblocks m6 AND roster-router P1) → 1s8/p9k/7mi → roster-router d5j→r6p→xm9→3u3/o5k.
3. Shadow session 2 (`conductor-ilv`) every session; first dry-run with an L item ready also verifies frv's routing effect live.
