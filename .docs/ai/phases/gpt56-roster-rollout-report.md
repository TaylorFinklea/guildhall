# GPT-5.6 roster rollout — report

**Completed:** 2026-07-10

## Landed

- Conductor `e4aeda9`: direct `codex` backend; explicit `reasoning_effort` on roster, Arena, ledger, dispatch, and drift comparison.
- Canonical rows: Sol=`max` Lead/Architect; Terra=`xhigh` Lead; Luna=`medium` Junior and `high` Senior. Luna accepts `low|medium|high|xhigh|max`, never `ultra`; Sol/Terra additionally accept `ultra`.
- Chezmoi scorecard/digest/tiers/loops `68d76d3` plus direct-Codex Ralph/global-policy source alignment. GPT-5.6 remains direct-Codex-only; no Pi/OpenCode aliases.
- Installed the current Conductor binary locally; refreshed model/harness scorecard reports and the read-only Guildhall Conductor demo report.

## Evidence

- `cargo test --locked`: 236 unit + 1 integration pass.
- `cargo clippy --all-targets --all-features --locked -- -D warnings`: pass.
- Installed `conductor config check` reports 25 roster entries; `conductor roster drift`: none.
- Ralph isolated preflight: Sol=`max`/Lead; Terra=`xhigh`/Lead; Luna default=`medium`/Junior; Luna `xhigh`=Senior; Luna `ultra` rejected (exit 2).
- Scorecard digest test plus both generated report validations: pass.
- `demo/run.sh conductor` dry-run passed; generated report validates.

## Deferred human step

- Do not wholesale-apply `~/.codex/config.toml`: its live file has unrelated runtime drift and currently carries Terra=`ultra`. Merge the source Terra=`xhigh` setting line-by-line only if desired.
