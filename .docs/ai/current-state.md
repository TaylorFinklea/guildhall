# Current State

> Updated at the end of every work session. Read this first.

## Active Branch

`main` (every member repo; all local, nothing pushed).

## Last Session Summary

**Date**: 2026-07-07→08 (Fable day #2 — orchestrated exec, full arc)

- **21 verified closes** (fleet → 76): fxo/bursar(V1-GATING)/h23/frv/**24e**(failover gates)/1s8/p9k · warden-vy1 · provenance-ba9/m5 · gauntlet-s7h/sr7/xqj/43t/**qgo**(sandbox v2)/**7mi**(lint+reasons) · hindsight-m4 · envoy-e2e/**hii** · **bursar-g0n**(weekly-window, honest-unknown). **Conductor clippy-green again; workspace 202/0.**
- **E2E bug-hunt arc**: runs 1–4 each caught a real product bug, all fixed same-day by the cheap fleet (prompt sandbox → read-refs → 120s timeout → fragment false-positives). Run-4 diagnosis: dispatch fails were transient provider-empty windows (probes falsified the timeout hypothesis); qwen judge lane swapped → ollama-minimax (3992bf7). **Run 5 detached (pid 99812, e2e-run5.log)** with all fixes aboard — any pass verdict closes `gauntlet-m4`.
- User decisions acted on: ceiling M→L (6ba5f91) · roster-router P1 this month (**now unblocked** via 24e) · lanes: opencode-go+ollama-cloud primary, NeuralWatt fallback-only. Conductor freeze (concurrent writer, user's OpenWiki commit 33903ea) lifted by user 22:26. **Shadow session 2: MATCH 1/3** (5/5 dispatchables identical; 2 structural exclusions → r6p scope).
- Incidents survived: ENOSPC (tesela target, 39.4G reclaimed), session restart (1 dispatch lost+recovered), 3 job kills (all root-caused). Shadow/queue ADRs + landmines from day arc stand.

## Build Status

- conductor 6fa9158: 202/0 + clippy `-D warnings` exit 0. gauntlet b27b009: 110/0, clippy 0. bursar bc213a3: 59/0, clippy 0. provenance b049f07: 58/0. hindsight e4cbdce: 148/0. warden 6660e28: 47/0. envoy 3de2908: validator green. Ledger ~245 rows; scorecard through 07-08 (ollama-minimax 7/7, ollama-kimi 1/1).

## Blockers

- gauntlet-m4 close awaits run-5 results (e2e-run5.log; if 7mi's lint refuses non-discriminating golden tasks, that's an M3-harvest-quality bead, not an m4 blocker). Human tails: harness-deck report `20260707-pending-decisions` Q2 still open.

## Resume plan

1. `bd prime` per repo. **Read ~/git/gauntlet/ai-scratch/e2e-run5.log** — any pass verdict → close gauntlet-m4 + tick roadmap; all refusals/fails now carry reason strings.
2. Fleet (primaries opencode-go+ollama-cloud, NeuralWatt fallback-only): roster-router chain d5j→r6p→xm9→3u3/o5k (defer expires 07-10, deps clear) → conductor-m6 (unblocked; config default junior/S per ADR).
3. Shadow session 3 (`conductor-ilv`) — 2 more consecutive MATCHes to cutover; queue is hygienic.
