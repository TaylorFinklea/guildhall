# Current State

Branch: `main` — local/unpushed. **`phases/unix-composability-spec.md` COMPLETE** — all
three slices shipped 2026-07-13. Guide: `USAGE.md`. ADRs: decisions.md `[2026-07-13]` ×3.

## Plan

**ALL SLICES SHIPPED.** conductor `b3631a0` · bursar `1fab043` · warden `b7a6205` ·
hindsight `2d80c5e` · provenance `e06d6df` · gauntlet `52828b9`.

- [x] **Slice 1 — the guardrails guard.** Six binaries on PATH. conductor's budget gate no
      longer fails open (`bursar unavailable` → SpendCautiously, was StaticCaps/Info).
      `bursar` added to `conductor config check` — the omission that let it hide. warden
      fails closed on crash. `gauntlet lint` static + exit 0. Rename fallout fixed.
      ~~S1.3~~ **WITHDRAWN**: "bursar exits non-zero on 401" was wrong — it would have made
      conductor discard the whole report. `status` is a REPORT; exit 0 is correct.
- [x] **Slice 2 — usable.** `--help` on all six (exit 0). `bursar check <provider>` →
      0/1/2/3, **fails closed** (unknown+error → 3, never 0).
- [x] **Slice 3 — the pipe.** `hindsight events --since <t>` — SIGPIPE-safe, redacts by
      risk (`commit_evidence` keeps its message — already in `git log`; every other kind's
      `input_summary` is cleared — a Bash command may hold a credential). `gauntlet cost
      --stdin` consumes it and **the forked pi-log parser is retired** (`grep pi/agent/logs
      gauntlet/src` → empty); `cost: 0` still → `unknown`, never `$0.00`.
      **`provenance annotate --events -` — the fuel line. 43/43 uncorrelated → 37.**
      Provenance now attributes authorship (`claude-opus-4-8 / lead`) on the very commits
      that built it.

## Blockers / awaiting human

- 🚨 **A concurrent Opus session `git reset` away a commit in `conductor` mid-work.** It
  survived only because a subagent recovered it from the reflog. **Charter invariant 5
  (one writer per repo) was violated by two of your own sessions.** Don't run parallel
  sessions on the same repo.
- **Anthropic OAuth token for bursar is EXPIRED** (live `HTTP 401`). That lane is blind, and
  `bursar check anthropic` correctly exits 3. Re-auth to restore it.
- Pre-existing: tiers.md efficiency patch; `conductor-xa5`; roster-router chain — slipped by
  the cost of this thrust, per the [2026-07-13] month-focus amendment.

## Open questions

- Provenance sees back only to **2026-07-12** (hindsight's transcript retention). 37 of 43
  guildhall commits are honestly uncorrelated for that reason, not a join defect. Is longer
  retention worth it?
- Filed, capping provenance's coverage: `hindsight-w5w` (events never carry
  `repo.git_commit`, so exact-hash correlation can't fire) · `hindsight-pov`
  (`extract_commit_message` misses ~21% of commits).
- conductor's own `provider-trust-integration-spec.md` (approved, unstarted) moves
  `unavailable` → `Defer`, stricter than the `SpendCautiously` shipped here. Compatible.
