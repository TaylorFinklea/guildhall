# GPT-5.6 roster rollout

**Status:** complete — verified 2026-07-10
**Scope:** Guildhall policy, Conductor dispatch/roster, chezmoi-managed Codex/Ralph/scorecard sources.

## Contract

- Keep `conductor.toml` as the canonical closed roster; preserve `gpt-5.5`.
- Add first-class Codex dispatch with a per-roster `reasoning_effort`; do not route GPT-5.6 through Pi.
- `gpt-5.6-sol`: Fable-equivalent architect / Lead, `max` reasoning.
- `gpt-5.6-terra`: Opus-equivalent Lead, `xhigh` reasoning.
- `gpt-5.6-luna`: Sonnet-equivalent; `low`/`medium` is Junior and `high`/`xhigh`/`max` is Senior. Canonical defaults are `medium` for the Junior row and `high` for the Senior row.
- Sol and Terra allow `low`, `medium`, `high`, `xhigh`, `max`, and `ultra`; Luna allows through `max` only. Reject an invalid row instead of silently falling back.
- Arena and Ralph must carry the selected Codex effort per invocation, rather than inheriting one global setting.
- Scorecard drift and generated digest must display and compare reasoning.

## Non-goals

- Do not retire GPT-5.5 or alter existing provider fallback policy.
- Do not implement the deferred broader roster-router/provider-policy refactor.
- Do not run `chezmoi apply` or overwrite unrelated live Codex config drift.
- Do not touch user-modified OpenWiki files.

## Verification

- `cargo test` and `conductor config check --config /Users/tfinklea/git/harness-conductor/conductor.toml`
- `conductor roster drift --config /Users/tfinklea/git/harness-conductor/conductor.toml`
- scorecard digest tests plus `harness-deck validate` for a generated report
- Ralph syntax and isolated Codex preflight checks
