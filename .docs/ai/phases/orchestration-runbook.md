# Fleet orchestration runbook — how to be the master of works

**Status**: operational handoff (Fable 5 → Opus, 2026-07-02). This is the
distilled how-to from the first real orchestration session (32+ dispatches,
22 beads verified-closed, zero failed verifies, 3 provider-limit events, 2
worker-crash recoveries). Conductor will eventually automate this loop; until
its M4 ships, the Lead session IS Conductor. Everything here is
execution-proven, not theoretical. *(The 2026-07-01 draft of this file was
truncated mid-write by a session limit; completed 2026-07-02 from the same
session's evidence.)*

## The loop (per bead)

1. **Pick**: `bd -C <repo> ready --json` — honor the build order (charter §
   Build order) and `tier_floor` in metadata. READ the bead's real floor
   before routing; a below-floor dispatch was nearly made once (envoy
   consult-prompt, lead-floor, almost went to a senior) — the gate works only
   if you check it.
2. **Claim**: `bd -C <repo> --actor <model> update <id> --claim < /dev/null`.
   Re-claim after a release needs `update <id> --assignee "<model>"` (claim
   errors if already claimed).
3. **Dispatch**: build the worker prompt from
   `~/git/conductor/templates/worker-prompt.md` — task data wrapped in
   delimiters as untrusted, rules AFTER the data, forbid push/bd/chezmoi/
   out-of-repo writes, require ONE commit + self-run verify. Backends:
   Claude-native work = in-session Sonnet subagent (Opus only for the hardest Lead work);
   pi = `pi --model <dispatch-id> --approve -p '…' < /dev/null` (stdin
   redirect is load-bearing); Codex = `codex exec -c 'model_reasoning_effort="<effort>"'
   --model <dispatch-id> '…'` (the roster supplies the effort); agy = needs
   `--add-dir "$PWD"` (and is quota-parked until ~2026-07-06). Sol=max and Terra=xhigh;
   Luna low/medium is Junior while high/xhigh/max is Senior. **One writer per repo at a time.**
4. **Verify by artifact**: YOU re-run the bead's `verify_cmd` and confirm a
   NEW commit exists — never trust the worker's word or exit code (exit codes
   are testimony; artifacts are evidence; agy exits 0 on quota no-ops — grep
   its invocation log for RESOURCE_EXHAUSTED). If the bead has a
   **human-verify tail** (list below), verify_cmd green is NOT acceptance —
   do the tail or flag it, never auto-close.
5. **Close or release**: verified → `bd -C <repo> close <id> --reason "<evidence:
   commit hash + verify output>"`. Worker died/limited → stash partials with
   the bead id in the stash message, comment the bead with exact resume state,
   release: `bd update <id> --status open --assignee ""`.
6. **Log**: every non-default-model run → a row in `~/.claude/model-bench.jsonl`
   (mirror the existing row shape) + a one-line Experience Log entry in
   `~/.claude/model-scorecard.md`.
7. **Report**: harness-deck checkpoint (kind: progress) every ~8 dispatches;
   escalations/decisions as ask/approval blocks. Validate with `hdeck validate`
   before publish (write is atomic to `~/.harness/reports/<project>/<run>/`).
   Lead-tier cores additionally get an **independent adversarial review by a
   different lead than the author** — it caught real bugs twice (conductor-rev1,
   warden-rev's mandate).

## Budget caps (user-approved 2026-07-02 — "Moderate")

Approval of the plan is approval of the caps (charter invariant 7):

- ≤ **10 bead closes per session**.
- ≤ **3 concurrent Anthropic subagents** (overloading tripped the session
  limit mid-write once — that's how this file got truncated).
- pi models: dispatch freely until the FIRST `429 5-hour usage limit` in
  worker output → release the bead + hold that provider; never retry into a
  limit.
- harness-deck checkpoint every ~8 dispatches (a checkpoint is a clean resume
  point).

## Provider-limit reality

Printed reset times in docs go stale — **check live at session start** (try a
cheap call per provider or read the statusline usage data). Known standing:
agy (gemini-flash) quota-dead until ~2026-07-06 — parked; junior work falls to
lean seniors (minimax). When ALL cheap backends are throttled, HOLD rather
than shifting the whole queue onto Anthropic.

## Human-verify tails (verify_cmd under-covers — flag, don't auto-close)

- `conductor-m3b` — run the dry-run cycle live, spot-check the plan output.
- `conductor-guildhall-dogfood` — dry-run over 3+ real fleet repos; check
  triage routing + dashboard rendering.
- `hindsight-m3-recap-report` — `harness-deck validate` the written report +
  eyeball the dashboard.
- `bursar-m4-cli` — run `bursar status --json` live; eyeball the anthropic
  window against reality.
- `provenance-m5` — dogfood run (`annotate` + `query unreviewed-junior` on
  provenance itself); check it renders cleanly.
- `gauntlet-m2-worktree-exec` — manual `gauntlet run --dry-run`; confirm git
  status stays clean.
- `gauntlet-m4-replay-verify-judge` — one real end-to-end run; confirm ledger
  rows land in the existing schema.

## Sequencing gates now encoded in bd (2026-07-02 hardening)

- `warden-m3` ← blocked on `warden-rev` (the M2 → LEAD review → M3 gate).
- `conductor-guildhall-dogfood` ← blocked on `conductor-m3b`.
- `hindsight-m5-hd-beads-sources` ← blocked on `hindsight-m3-recap-report`.
- `foreman-*` (all 6) — status **deferred**: built LAST; un-defer when the
  other six members ship v1.
- `conductor-warden` — status **deferred** (v1.5).
- `conductor-review` — **P1, gates v1** (user decision 2026-07-02; ADR in
  decisions.md).

Cross-REPO edges stay prose-only (bd has no cross-repo primitive) — the graph
lives in `guildhall-integration-v1-spec.md`; honor it manually.

## Crash/limit recovery (twice-proven)

Current stashes: `provenance` stash@{0} (m2 store.rs partial — pop and build
on it); `hindsight` stash@{0} (m2-pi partial — **orphan-file landmine**: the
stash uses the spec's old `pi_session.rs` filename; fold into the committed
`pi.rs`, see the bead comment + hindsight decisions.md ADR 2026-07-02).
