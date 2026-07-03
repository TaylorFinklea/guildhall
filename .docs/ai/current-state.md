# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-02 → 07-03 (Fable/Opus exec #1–#2d + **month handoff hardening**)

- **20 beads closed 07-02→03 arc, 0 failed verifies** (fleet → **55**). Latest: **`conductor-review` — the v1 gate SHIPPED** (c01377d, gpt-5.5; 4/4 review tests, 153 regression + clippy green). Conductor **v1 code-complete**; v1-done now needs only conductor-bursar + member milestones + human tails.
- **MONTH DIRECTION LOCKED with the user (2026-07-03)** — 4 product calls, encoded durably:
  autonomy ladder leads · earned junior/S auto (config default; spec ceiling unchanged) ·
  shadow-first cutover (3 matching sessions) · strict Claude reserve (+structurally-Claude carve-out).
  → `phases/2026-07-autonomy-month-spec.md` (THE plan) · decisions.md ADRs `[2026-07-03]` ×4 ·
  `opus-handoff-prompt.md` (rewritten for month operation) · roadmap restructured Phase A/B.
- Bead layer updated: conductor-bursar + h23 → P1 (+why comments); m6 carries the config-default ADR comment; NEW: `conductor-ilv` (shadow→cutover, lead), clippy sweeps `warden-vy1`/`provenance-ba9`/`gauntlet-s7h`, `warden-44n` (pi-wrapper, P3 capture); envoy-e2e carries its Sonnet routing comment. bd remembers: fleet-dispatch-landmines, autonomy-month-direction (conductor); opus-month-handoff (guildhall).

## Build Status

- conductor **c01377d**: 153 tests + clippy green (v1 code-complete). hindsight d155419 (103+34 + clippy green). bursar db7fbfd (green). provenance 36c0d16, gauntlet 7091425, warden d3028c9 (tests green; clippy sweeps queued as beads).
- Logs: `~/.claude/model-bench.jsonl` (187 rows) + scorecard Experience Log through exec #2d + review.

## Blockers

- **opencode-go** weekly cap → resets ~2026-07-05. **agy** → ~07-06. **gpt-5.5** cycling (~3 heavy items/5h) — just did conductor-review, assume ~5h to next window.

## Resume plan (next session — Opus, month posture)

1. Read `opus-handoff-prompt.md` → month spec → ADRs. `bd prime` per repo.
2. Work roadmap **Phase A** via `bd ready` (fleet-first, strict reserve; envoy-e2e on Sonnet).
3. Run the **shadow protocol** every session (bead `conductor-ilv`).
4. Nag the user on the human tails + pending-human items (list in opus-handoff-prompt.md).
