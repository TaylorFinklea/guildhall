# Workflows — Orchestration, Dispatch, and the Autonomy Ladder

This page covers how work actually gets done in the Guildhall suite: the
per-bead dispatch loop, budget caps and provider-limit handling, the shadow
protocol that earns Conductor its autonomy, and the month-level plan that
governs Phase A (close v1) and Phase B (the autonomy ladder).

## The orchestration loop (per bead)

The canonical per-bead cycle lives in the
[orchestration runbook](../.docs/ai/phases/orchestration-runbook.md). It was
distilled from the first real orchestration session (32+ dispatches, 22 beads
verified-closed, zero failed verifies) and is execution-proven, not theoretical.
Until the shadow protocol cuts over to `conductor dispatch`, the Lead session
still verifies by artifact and records whether Conductor's dry-run routing matches
the human/Opus route.

The seven steps:

1. **Pick** — `bd -C <repo> ready --json`. Honor the build order (charter § Build
   order) and read the bead's actual `tier_floor` metadata before routing.
   Below-floor pickup stops and flags. Round *up* complexity when unsure.
2. **Claim** — `bd -C <repo> --actor <model> update <id> --claim < /dev/null`.
   Re-claim after release uses `--assignee` (claim errors if already claimed).
   **Never `bd ready --claim` speculatively** — it mutates state.
3. **Dispatch** — Build the worker prompt from
   `~/git/harness-conductor/templates/worker-prompt.md`: task data wrapped in
   delimiters as untrusted, rules AFTER the data, forbid push/bd/chezmoi/
   out-of-repo writes, require ONE commit + self-run verify.
   - Claude work → in-session Sonnet subagent (Opus only for lead-floor).
   - pi → `pi --model <dispatch-id> --approve -p '…' < /dev/null` (stdin redirect
     is load-bearing).
   - agy → needs `--add-dir "$PWD"`.
   - **One writer per repo at a time.** Cross-repo parallelism is fine.
4. **Verify by artifact** — YOU re-run the bead's `verify_cmd` and confirm a NEW
   commit exists. Never trust the worker's word or exit code alone (see
   [Exit codes are testimony](architecture.md#exit-codes-are-testimony) on the
   architecture page). If the bead has a **human-verify tail** (list below),
   `verify_cmd` green is NOT acceptance — do the tail or flag it, never auto-close.
5. **Close or release** — Verified → `bd -C <repo> close <id> --reason "<evidence:
   commit hash + verify output>"`. Worker died/limited → stash partials with the
   bead id in the stash message, comment the bead with exact resume state,
   release: `bd update <id> --status open --assignee ""`.
6. **Log** — Every non-default-model run gets a row in
   `~/.claude/model-bench.jsonl` (mirror the existing row shape) + a one-line
   Experience Log entry in `~/.claude/model-scorecard.md`.
7. **Report** — harness-deck checkpoint (kind: progress) every ~8 dispatches;
   escalations/decisions as ask/approval blocks. Validate with `hdeck validate`
   before publish. Lead-tier cores additionally get an **independent adversarial
   review by a different lead** — it caught real bugs twice.

### Human-verify tails

These beads have verify gaps that `verify_cmd` alone does not cover. Flag, don't
auto-close:

| Bead | Tail |
|---|---|
| `conductor-m3b` | Run the dry-run cycle live, spot-check plan output |
| `conductor-guildhall-dogfood` | Dry-run over 3+ real fleet repos, check triage + dashboard |
| `hindsight-m3-recap-report` | `harness-deck validate` the report + eyeball the dashboard |
| `bursar-m4-cli` | Run `bursar status --json` live, eyeball anthropic window vs reality |
| `provenance-m5` | Dogfood run (`annotate` + `query unreviewed-junior`) on provenance itself |
| `gauntlet-m2-worktree-exec` | Manual `gauntlet run --dry-run`, confirm git status stays clean |
| `gauntlet-m4-replay-verify-judge` | One real end-to-end run, confirm ledger rows land in existing schema |

### Shell landmines

All of these have been bitten in production. See also the autonomy month spec's
landmine section and `bd memories landmine`.

- TUI CLIs get `< /dev/null` — always.
- agy gets `--add-dir "$PWD"`.
- `bd ready --claim` mutates — never speculative.
- `bd init --stealth` edits the tracked `.gitignore` — revert it (the mechanism
  is `.git/info/exclude`).
- Background jobs get killed in long sessions — strictly serial dispatch.
- `git stash drop` is classifier-blocked for agents — superseded stashes
  (provenance-m2, hindsight-m2) are a human todo.

## Budget caps and provider-limit handling

Budget caps ride with the plan (charter invariant 7). The user-approved
"Moderate" caps (2026-07-02):

- ≤ **10 bead closes per session**.
- ≤ **3 concurrent Anthropic subagents** (overloading tripped the session limit
  mid-write once).
- pi models: dispatch freely until the FIRST `429 5-hour usage limit` in worker
  output → release the bead + hold that provider; never retry into a limit.
- harness-deck checkpoint every ~8 dispatches.

### Provider quota rhythms

Printed reset times go stale — check live at session start. Known standing at
the 2026-07-03 handoff:

| Provider | Rhythm | Notes |
|---|---|---|
| gpt-5.5 (openai-codex) | ~3 heavy items per 5h window, then ~5h reset | cycling; poller pattern works |
| opencode-go (qwen/glm/minimax) | ONE shared workspace **weekly** cap | dead until ~2026-07-05 |
| agy (gemini-3.5-flash) | per-model quota; fail-open exit-0 bug | dead until ~2026-07-06; grep cli log for `RESOURCE_EXHAUSTED` |

When ALL cheap backends are throttled, HOLD rather than shifting the whole queue
onto Anthropic. The strict Claude-reserve policy (see routing rules below) makes
this explicit.

Bursar + `conductor-bursar` exist to mechanize this table. While building it,
verify bursar's window shapes actually surface the opencode WEEKLY window
(`limitName:"weekly"` in 429 metadata).

## The autonomy month (2026-07)

The full month plan lives in
[2026-07-autonomy-month-spec.md](../.docs/ai/phases/2026-07-autonomy-month-spec.md).
Mission: take Conductor from "planner that proposes" to "orchestrator that earns
dispatch authority" — the **autonomy ladder** — while closing out v1.

### Phase A — close v1 (~week 1)

v1-done = dry-run cycle ✅ + bursar budget + conductor-review + every member at
final milestone (foreman explicitly excepted). Key remaining items at the
2026-07-07 state:

- `conductor-bursar` (P1, v1-gating) — fleet.
- `conductor-h23` (P1, autonomy precondition: silent-empty scan fix) — fleet.
- `provenance-m5` (member final milestone) — fleet.
- `gauntlet-m4` (replay+judge, L) — fleet; E2E runs 1–4 each caught a real bug,
  all fixed same-day; run 5 in flight at handoff.
- `hindsight-m4-fixtures-hardening` (P3) — fleet.
- `envoy-e2e-dryrun` — **structurally-Claude** (skill dogfood) → Sonnet.
- Clippy sweeps ×3 (warden, provenance, gauntlet) — fleet.
- Human tails (non-gating, the user closes them).

### Phase B — autonomy ladder (weeks 2–4)

Order matters:

1. **conductor-m6 (ratchet)** — mechanism per spec § Ratchet ({senior,junior}/
   ≤M ceiling, 3 clean cycles to unlock, any failure → relock, invariant 9).
   Month-1 config default is **narrower: junior-floor + S-complexity only**.
   Widening toward the spec ceiling is a human config change backed by ratchet
   evidence, not a code change.
2. **conductor-m5 (triage-suggest backfill)** — metadata hygiene at scale; needed
   once conductor routes repos whose beads lack `tier_floor`/`complexity`.
3. **Shadow protocol** (bead `conductor-ilv`, lead-floor) — see below.
4. **Post-cutover hardening** — ratchet unlock in production, m5 backfill on a
   real untriaged repo, budget decisions visible in cycle reports.

### The shadow protocol (cutover criterion)

Every Opus session runs `conductor cycle --dry-run` alongside hand-orchestration
and diffs Conductor's plan vs actual routing. The verdict is recorded as a bd
comment on bead `conductor-ilv`.

**Cutover criterion**: 3 consecutive sessions where the plan matches Opus's
routing (or diverges only in ways Opus judges equal-or-better). Mismatches are
bugs or triage gaps — file beads, don't shrug. After cutover, `conductor
dispatch` (approval-gated) becomes the default work loop; hand-dispatch becomes
the exception.

Status at 2026-07-07→08 handoff: shadow session 2 = MATCH 1/3 (5/5
dispatchables identical, 2 structural exclusions → r6p scope). Session 1 was
NO-MATCH 0/3; remediations applied (queue hygiene, ceiling bead, routing_intent
gap → roster-router P1).

### Routing rules (ADR-locked)

- **Claude = orchestration/verify (Opus) + lead-floor beads (Sonnet) +
  adversarial review of L-items + structurally-Claude beads** (skill dogfoods
  like `envoy-e2e-dryrun` → Sonnet).
- **Everything else → the external fleet.** When the fleet is quota-dead, WAIT
  (poller pattern: probe `pi --model openai-codex/gpt-5.5 --no-tools -p 'reply
  PONG' </dev/null` every ~20min). No P1 exception.
- `tier_floor` is a hard gate — fleet never owns lead-floor; below-floor → stop
  and flag.

### What NOT to do this month

- No Envoy live transport, no `hindsight why`, no Warden pi/agy live-gating
  builds (`warden-44n` is P3 capture only), no foreman un-defer, no conductor
  daemon, no silent autonomy-config widening.
- Don't re-architect: mechanism questions → the pinned specs; product questions
  → the user.

### Month-end definition of done

1. v1-done clause satisfied (incl. human tails closed off or explicitly waived
   by the user).
2. Ratchet live with ≥1 repo genuinely unlocked and ≥1 relock-on-failure
   observed (or honest evidence why no repo earned it).

## Where to look

| What | Source |
|---|---|
| Full month plan | [`.docs/ai/phases/2026-07-autonomy-month-spec.md`](../.docs/ai/phases/2026-07-autonomy-month-spec.md) |
| Orchestration runbook (the loop, caps, tails) | [`.docs/ai/phases/orchestration-runbook.md`](../.docs/ai/phases/orchestration-runbook.md) |
| Opus handoff prompt (month-level briefing) | [`.docs/ai/opus-handoff-prompt.md`](../.docs/ai/opus-handoff-prompt.md) |
| Live state + resume plan | [`.docs/ai/current-state.md`](../.docs/ai/current-state.md) |
| Roadmap (Now/Next/Later) | [`.docs/ai/roadmap.md`](../.docs/ai/roadmap.md) |
