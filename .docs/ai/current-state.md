# Current State

Branch: `main` — local/unpushed. Active: `phases/unix-composability-spec.md` (fourth
thrust, user-authorized 2026-07-13; ADRs in decisions.md).

## Plan

Slice 1 — safety. Items 1+2 MUST land in one commit (see spec).

- [ ] S1.1+1.2 — symlink 6 binaries → `~/.local/bin`; conductor `bursar unavailable` →
      `SpendCautiously`/`Warn` (mirror the `unknown` arm), never `StaticCaps`/`Info`.
      Verify: `command -v conductor bursar warden hindsight provenance gauntlet && cargo test --manifest-path ~/git/conductor/Cargo.toml`
- [ ] S1.3 — bursar exits non-zero on provider auth/quota failure (live 401 → exit != 0).
      Verify: `cargo test --manifest-path ~/git/bursar/Cargo.toml`
- [ ] S1.4 — conductor `scan`: exit 0 on ordinary skips + accept `--config`.
      Verify: `cd /tmp && conductor scan --json --config ~/git/conductor/conductor.toml; test $? -eq 0`
- [ ] S1.4b — add `bursar` to `conductor config check` preflight (would have caught C2).
      Verify: `cargo test --manifest-path ~/git/conductor/Cargo.toml`
- [ ] S1.5 — warden: fail closed (non-zero + deny JSON) on crash/malformed stdin; leave
      allow/ask/deny at exit 0.
      Verify: `cargo test --manifest-path ~/git/warden/Cargo.toml`
- [ ] S1.6 — fix `harness-conductor` rename fallout (README, demo/run.sh, gauntlet golden `origin_path`).
      Verify: `cd ~/git/gauntlet && ./target/release/gauntlet lint golden-tasks; test $? -eq 0`
- [ ] S1.7 — `gauntlet lint` static: no live worktree ops.
      Verify: `cd ~/git/gauntlet && ./target/release/gauntlet lint golden-tasks && git -C ~/git/warden status --porcelain | wc -l | grep -q '^ *0$'`
- [ ] S1.8 — regression test on the bursar↔conductor seam (nothing tests it; that is why C2 shipped).
      Verify: `cargo test --manifest-path ~/git/conductor/Cargo.toml`
- [ ] S2.9 — `--help` on all six binaries.
      Verify: `for t in conductor bursar warden-claude-pretooluse hindsight provenance gauntlet; do $t --help >/dev/null || exit 1; done`
- [ ] S2.10 — refresh `USAGE.md` to post-Slice-1 truth (drop absolute paths + landmines 1-5,7).
      Verify: every command in USAGE.md runs from a clean shell
- [ ] S3.11+3.12 — `hindsight events --since <t> --json` (SIGPIPE-safe, redacted,
      carries `artifact{path,sha256}`) SHIPPED WITH its consumer `gauntlet cost --stdin`;
      retire `gauntlet/src/cost.rs`'s forked pi-log parser.
      Verify: `hindsight events --since 30d | head -1 && ! grep -rq 'pi/agent/logs' ~/git/gauntlet/src && cargo test --manifest-path ~/git/gauntlet/Cargo.toml`

## Blockers / awaiting human

- **Anthropic OAuth token for bursar is EXPIRED** — live `HTTP 401: Invalid bearer token`.
  bursar's anthropic lane is blind until re-auth. (Human: re-auth.)
- Pre-existing: tiers.md efficiency patch approval; `conductor-xa5`; roster-router chain.
  These SLIP by the cost of this thrust — accepted in the [2026-07-13] month-focus amendment.

## Open questions

- Slice 3 redaction scope. If a full classifier is too large, fall back to `--redact` on
  by default with explicit opt-out. **Never ship raw transcripts to stdout.**
