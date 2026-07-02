# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed)

## Last Session Summary

**Date**: 2026-07-02 (Fable architect handoff)

- Guildhall chartered + all 8 repos specced/backlogged; ~23 beads dispatched, verified-by-artifact, and closed across Conductor + members.
- **Done + verified**: Conductor cycle 1 COMPLETE (8/8 + Opus adversarial review that found a real untested safety guard). envoy (validator/consult-prompt/skill/handoff — only e2e left). warden m0/m1/m2 (classify+policy+state, the policy core). hindsight m0/m1/m2-codex. bursar m0. provenance m0/m1.
- **Fable gap review** (this session): found + filed 4 gap beads (see roadmap Now) and wrote `phases/guildhall-integration-v1-spec.md` (the vertical slice + cross-repo dep graph + v1-done definition) + 2 ADRs.

## Build Status

- All closed beads verified (orchestrator re-ran each verify_cmd). All repos build clean at their last closed bead.
- **warden caveat**: warden-m0's commit (6bf2100) had a partial classify.rs amended in by a killed worker; warden-m1 (b617a24) completed the port properly on top. Fine now.
- **Stashed partial work** (killed by Anthropic limit, recoverable): `provenance` (`git stash list` → provenance-m2 partial), `hindsight` (→ hindsight-m2-pi partial). Redo may `git stash pop` or start fresh.

## Blockers — backend rate limits (as of 2026-07-02 ~00:00 CT)

- **Anthropic** (Sonnet/Opus/Fable): session limit, resets **2:10am CT**.
- **opencode-go** (glm/minimax/qwen via pi): 5h limit, resets ~00:00–00:30 CT.
- **openai-codex** (gpt-5.5): usage limit hit; reset unknown.
- **agy** (gemini-3.5-flash): quota-exhausted until ~2026-07-06.

## Resume plan (Opus takes over execution)

1. Read `phases/guildhall-integration-v1-spec.md` (the seams + v1-done) and this file.
2. `bd -C <repo> ready` per member; honor `tier_floor` gates. Released/ready now: `warden-rev` (LEAD review of the policy core — Opus or Sonnet, NOT senior), `hindsight-m2-pi-parser` (stash available), `provenance-m2` (stash available), `bursar-m1-anthropic`, plus the 4 new gap beads.
3. Route by capacity: senior/junior → pi (glm/minimax/qwen/gpt-5.5) once un-limited; lead-floor reviews → Claude lead. Every close gated on re-running the bead's verify_cmd. Log each dispatch to `~/.claude/model-bench.jsonl` + scorecard.
4. Cross-repo deps are prose-only — honor the graph in the integration spec.
5. Pending-human (never fleet-applied): rotate the plaintext claude.ai session-key in `~/.claude/fetch-claude-usage.swift`; envoy/warden/gauntlet chezmoi installs + tiers.md patch.
