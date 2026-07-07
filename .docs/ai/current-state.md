# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-07 (Fable day #2 — orchestrated exec)

- **9 verified closes** (fleet → 64): conductor-fxo/bursar(V1-GATING)/h23 · warden-vy1 · provenance-ba9(no-op)/m5 · gauntlet-s7h · hindsight-m4 · envoy-e2e(Sonnet). `gauntlet-m4` code shipped a94008a + reviewed; **E2E verify CAUGHT A P1** → `gauntlet-sr7` (harvested prompts carry real-repo abs paths vs worktree sandbox; arena-judge class; repos verified clean) blocks m4. +`gauntlet-7mi`. Budget config → gpt-5.5 worker/cap 6 (c795fb6).
- **Phase A: done except gauntlet-m4 E2E + human tails.** Shadow session 1 recorded on `conductor-ilv` (NO-MATCH 0/3; 4 mismatch classes; remediations landed). Roster-router spec split → 5 dep-chained beads (deferred 07-10).
- **11 beads filed** (review findings 24e/1s8/p9k, bursar-g0n, envoy-hii, frv ceiling, 5×roster-router). 2 ADRs `[2026-07-07]` (queue-encodes-plan; secrets-routing). Landmines memory +4 (unattended clause, whole-tree verify, opencode-go drops, pi-log recovery).
- **Lane news**: ollama-cloud/minimax 2/2 verified closes (scorecard bumped); opencode-go dropped 2 sessions mid-work (exit 0, no error); gpt-5.5 2 heavy closes + 1 scope-stray (reverted, preserved as d5j reference patch).

## Build Status

- conductor a94008a-era: 199/0 + 17 clippy warnings (sweep = p9k). gauntlet a94008a 41/0 clippy 0. provenance b049f07 58/0. hindsight e4cbdce 148/0. warden 6660e28 47/0 clippy 0. Ledger 232+ rows; scorecard Experience Log through 07-07.

## Blockers

- `gauntlet-sr7` (P1 SAFETY) blocks gauntlet-m4 close. User: `conductor-frv` ceiling + roster-router slot (harness-deck asks, report 20260707-fable-day2) + human tails (roadmap Now).

## Resume plan

1. `bd prime` per repo. Check harness-deck responses.json (2 asks pending).
2. Fleet: `gauntlet-sr7` (P1, unblocks m4 E2E re-run → close m4) → conductor-24e (m6 blocker) → 1s8/p9k/7mi → roster-router P1 (post-07-10, if user confirms).
3. Shadow session 2 (`conductor-ilv`) every session; queue is hygienic now.
