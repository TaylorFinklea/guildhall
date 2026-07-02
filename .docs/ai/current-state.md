# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed)

## Last Session Summary

**Date**: 2026-07-02 (Fable handoff-hardening audit — 9-repo fan-out)

- Full audit: 48 open beads across 9 repos, ALL with tier_floor/complexity/verify_cmd in bd metadata; zero dangling refs; builds green (conductor 84 tests, warden 39, hindsight 59, bursar 4, provenance clean). Closed count corrected: **22** (not 23).
- Gates encoded in bd: warden-m3←warden-rev; conductor-guildhall-dogfood←conductor-m3b; hindsight-m5←hindsight-m3; foreman ×6 deferred (build-order); conductor-warden deferred (v1.5).
- `conductor-review` → P1, **gates v1** (user decision; ADR in decisions.md; integration spec amended).
- Landmine/staleness comments filed on 6 beads; hindsight module-layout + M5-scope ADRs added; orchestration-runbook.md COMPLETED (was truncated); conductor/warden/hindsight plan docs refreshed.
- Budget caps user-approved ("Moderate"): ≤10 closes/session, ≤3 concurrent Anthropic, pi until 429→hold, checkpoint every ~8 (runbook § Budget caps).

## Build Status

- All repos build clean at HEAD; all closed beads verified by artifact.
- Stashes: `provenance` (m2 store.rs partial — pop + build on), `hindsight` (m2-pi partial — orphan-file landmine, fold into pi.rs; see bead comment + hindsight ADR).

## Blockers

- Provider-limit notes from 2026-07-01/02 are STALE — check live at session start (runbook § Provider-limit reality). Standing: agy quota-dead until ~2026-07-06.

## Resume plan (Opus executes)

1. Read `opus-handoff-prompt.md` → `orchestration-runbook.md` → integration spec; `bd prime` in any member.
2. `bd -C <repo> ready` per member — gates are now in bd. Ready today: warden-rev (LEAD, do first — m3 waits on it), hindsight-m2-pi-parser, provenance-seam (LEAD) + provenance-m2, bursar-m1/m2/m3, envoy-e2e-dryrun, conductor m4a/m3a/m1c/m0c/agy/cov1, gauntlet-m0.
3. Honor the runbook caps; verify by artifact; log dispatches; checkpoint to harness-deck.
4. Pending-human (never fleet-applied): rotate plaintext claude.ai session-key in `~/.claude/fetch-claude-usage.swift`; envoy/warden/gauntlet chezmoi installs + tiers.md patch.
