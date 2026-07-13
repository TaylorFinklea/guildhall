# Current State

Branch: `main` — local/unpushed. Active: `phases/unix-composability-spec.md` (fourth
thrust, user-authorized 2026-07-13; ADRs in decisions.md). Guide: `USAGE.md`.

## Plan

**Slice 1 SHIPPED 2026-07-13** — conductor `08b35b4` · warden `49157c8` · gauntlet
`490655c` · guildhall docs. Six binaries symlinked into `~/.local/bin`. See spec § AS BUILT.

- [x] S1.1+1.2 — six binaries on PATH; conductor `bursar unavailable` → `SpendCautiously`
      (was `StaticCaps`/`Info`). Budget gate no longer fails open.
- [x] S1.4 — `conductor scan` exits 0 on ordinary skips. (`--config` already existed; only
      the USAGE string omitted it.)
- [x] S1.4b — `bursar` added to `conductor config check` preflight — the omission that let C2 hide.
- [x] S1.5 — warden fails closed on crash: deny JSON on stdout + exit 1. allow/ask/deny stay exit 0.
- [x] S1.6 — rename fallout fixed (guildhall README + demo + runbook + briefing; gauntlet golden
      task, its `prompt` field, and `gauntlet.toml` read_only_refs).
- [x] S1.7 — `gauntlet lint` static; discrimination check moved to `validate --smoke-run`,
      and lint now PRINTS what it no longer covers.
- [x] S1.8 — regression test on the bursar↔conductor seam.
- [x] ~~S1.3~~ **WITHDRAWN** — "bursar exits non-zero on 401" was wrong; it would have made
      conductor discard the whole report. `bursar status` is a report; exit 0 is correct.
      Replaced by a `bursar check <provider>` predicate → Slice 2.

- [ ] S2.9 — `--help` on all six binaries.
      Verify: `for t in conductor bursar warden-claude-pretooluse hindsight provenance gauntlet; do $t --help >/dev/null || exit 1; done`
- [ ] S2.9b — `bursar check <provider>` exit-code predicate (0=affordable, non-zero=no/unknown/error).
      Verify: `cargo test --manifest-path ~/git/bursar/Cargo.toml`
- [ ] S2.10 — keep `USAGE.md` honest as Slice 2 lands.
      Verify: every command in USAGE.md runs from a clean shell
- [ ] S3.11+3.12 — `hindsight events --since <t> --json` (SIGPIPE-safe, redacted, carries
      `artifact{path,sha256}`) SHIPPED WITH its consumer `gauntlet cost --stdin`; retire
      `gauntlet/src/cost.rs`'s forked pi-log parser.
      Verify: `hindsight events --since 30d | head -1 && ! grep -rq 'pi/agent/logs' ~/git/gauntlet/src && cargo test --manifest-path ~/git/gauntlet/Cargo.toml`

## Blockers / awaiting human

- ~~conductor's `[[repo_policy]]` table uncommitted~~ — **RESOLVED** in conductor `5e6fab3`
  ("free-train lanes were dark"). 11 rows now in version control; conductor 242/242 green.
- **Anthropic OAuth token for bursar is EXPIRED** — live `HTTP 401`. That lane is blind.
- Pre-existing: tiers.md efficiency patch; `conductor-xa5`; roster-router chain — SLIP by
  the cost of this thrust, per the [2026-07-13] month-focus amendment.

## Open questions

- Slice 3 redaction scope. If a full classifier is too large, fall back to `--redact` on by
  default with explicit opt-out. **Never ship raw transcripts to stdout.**
- conductor's own `provider-trust-integration-spec.md` (approved, unstarted) moves
  `unavailable` → `Defer`, stricter than the `SpendCautiously` shipped here. Compatible;
  sequence it deliberately rather than discovering the overlap twice.
