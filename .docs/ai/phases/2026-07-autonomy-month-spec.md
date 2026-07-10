# Guildhall — autonomy month (2026-07-03 → ~2026-08-01)

> Architectural direction from Fable (Lead), locked with the user 2026-07-03. Opus 4.8 owns
> execution for the month. Product calls live in decisions.md ([2026-07-03] ADRs ×4) — don't
> relitigate; if reality contradicts this spec, update the spec + note why, don't silently drift.

## Mission

Take Conductor from "planner that proposes" to "orchestrator that earns dispatch authority" —
the **autonomy ladder** — while closing out v1. By month end: Conductor runs the guild's own
backlog in shadow, matches Opus's hand-routing, cuts over to conductor-driven dispatch with
the earned-autonomy ratchet live (junior/S auto; everything else approval-gated).

## Phase A — close v1 (~week 1)

v1-done (integration spec) = dry-run cycle ✅ + **bursar budget** + **conductor-review** +
every member at final milestone (foreman explicitly excepted — built last, stays deferred).

| Item | Repo | Why it's Phase A | Route |
|---|---|---|---|
| conductor-review (P1, L) | conductor | GATES v1 (ADR 2026-07-02) | in flight on gpt-5.5 |
| conductor-bursar (P1, M) | conductor | **v1-gating** — integration-spec step 2 | fleet |
| conductor-h23 (P1, S) | conductor | autonomy PRECONDITION: silent-empty scan = auto-dispatch on false data | fleet |
| provenance-m5 (M6 query.rs) | provenance | member final milestone | fleet |
| gauntlet-m4 (replay+judge, L) | gauntlet | member final milestone | fleet |
| hindsight-m4-fixtures-hardening (P3) | hindsight | member completion (secrets-audit) | fleet |
| envoy-e2e-dryrun | envoy | member final milestone; **structurally-Claude** (skill dogfood) | Sonnet (ADR carve-out) |
| clippy sweeps ×3 (new beads) | provenance/gauntlet/warden | latent lint debt; repos should enter autonomy month gate-green | fleet (S) |
| Human tails | — | dogfood dashboard eyeball → human closes `conductor-guildhall-dogfood`; m3b render; hindsight-m3 eyeball; bursar seven_day smokes | human |

## Phase B — autonomy ladder (weeks 2–4)

Order matters:

1. **conductor-m6 (ratchet)** — mechanism per pinned spec § Ratchet ({senior,junior}/≤M ceiling,
   3 clean cycles to unlock, any failure → relock, invariant 9). **Month-1 config DEFAULT is
   narrower: junior-floor + S-complexity only** (ADR [2026-07-03] autonomy posture). Widening
   toward the spec ceiling is a HUMAN config change backed by ratchet evidence, not a code change.
2. **conductor-m5 (triage-suggest backfill)** — metadata hygiene at scale; needed once conductor
   routes repos whose beads lack tier_floor/complexity. Fail-closed JSON validation per bead spec.
3. **Shadow protocol** (bead `conductor-shadow-cutover`, lead-floor): every Opus session runs
   `conductor cycle --dry-run` alongside hand-orchestration; diff conductor's plan vs actual
   routing; record match/mismatch as a bd comment on the bead. **Cutover criterion: 3 consecutive
   sessions where the plan matches Opus's routing (or diverges only in ways Opus judges equal-or-better).**
   After cutover: `conductor dispatch` (approval-gated) is the default work loop; hand-dispatch
   becomes the exception. Mismatches = bugs or triage gaps — file beads, don't shrug.
4. **Post-cutover hardening** (as evidence demands): ratchet unlock in production, m5 backfill on
   a real untriaged repo, budget decisions visible in cycle reports.

## Routing rules (standing, from the ADRs)

- **Strict Claude reserve**: Claude = orchestration/verify (Opus), lead-floor beads (Sonnet),
  adversarial review of L-items, and **structurally-Claude** beads (skill dogfoods like envoy-e2e).
  Senior fleet-eligible work WAITS for fleet resets — poller pattern, never idle-burn Sonnet on it.
- **Fleet dispatch**: direct `pi --model <id> --approve -p "$(cat prompt)" </dev/null`, ONE
  background job at a time, verify-by-artifact before every close (re-run exact verify_cmd +
  confirm a real commit). L-items get an Opus adversarial pass.
- **GPT-5.6 Codex routing**: Sol is the Fable-equivalent Architect at `max`; Terra is the
  Opus-equivalent Lead at `xhigh`; Luna is Sonnet-equivalent with `low`/`medium` as Junior and
  `high`/`xhigh`/`max` as Senior. These are metered external routes, never substitutes for a
  structurally-Claude harness requirement; Luna does not accept `ultra`.
- **tier_floor is a hard gate** — only a Lead-tier roster entry may own lead-floor work; below-floor
  → stop and flag. The Codex Sol/Terra rows qualify where the task is not structurally-Claude.

## Provider quota calendar + rhythms (observed, 2026-07-02/03)

| Provider | Rhythm | State at handoff |
|---|---|---|
| gpt-5.5 (openai-codex) | ~3 heavy items per 5h window, then ~5h reset | cycling; poller pattern works |
| opencode-go (qwen/glm/minimax) | ONE shared workspace **weekly** cap | dead until ~2026-07-05 |
| agy (gemini-3.5-flash High) | per-model quota; fail-open exit-0 bug (grep cli-log for RESOURCE_EXHAUSTED) | dead until ~2026-07-06 |

Bursar + conductor-bursar exist to mechanize exactly this table. While building it, verify
bursar's window shapes actually surface the opencode WEEKLY window (limitName:"weekly" in the
429 metadata); if not → file a bursar bead rather than widening conductor-bursar's scope.

## Landmines (all bitten this session — bd remember has pointers)

1. Dispatch harness in /tmp scratchpad does NOT survive session interruption — keep prompts in
   the bead text or repo-local ai-scratch; reconstruct from bd if wiped.
2. Background jobs get killed in long sessions — strictly serial dispatch; a killed pi can leave
   partial work that surfaces AFTER the kill (re-check `git status` before re-dispatch; discard partials).
3. Exit codes lie: glm silent no-op (exit 0, no commit), agy fail-open (exit 0 on 429), rc=124
   timeout AFTER completing work (hindsight-m3 — check the tree before declaring failure).
4. Per-bead `cargo test` verify never runs clippy → repos accumulate lint debt. conductor/hindsight/
   bursar gates green; provenance/gauntlet/warden sweeps are Phase A beads. **New-bead rule: prefer
   `cargo test && cargo clippy --all-targets -- -D warnings` as verify_cmd for Rust impl beads.**
5. Agent `git stash drop` is classifier-blocked — superseded stashes (provenance-m2, hindsight-m2)
   remain a HUMAN todo.
6. minimax/gpt-5.5 self-edit repo handoff docs (habit, so far accurate) — review those hunks in
   verify, don't auto-flag as scope violation.

## What NOT to do this month

- No Envoy live transport, no `hindsight why`, no Warden pi/agy live-gating builds (captured as
  P3 backlog: `warden-wrapper` bead), no foreman un-defer, no conductor daemon. These are the
  NEXT month's candidates, gated on the autonomy ladder holding in production.
- Don't widen the autonomy config past junior/S without the human flipping it.
- Don't re-architect: mechanism questions → the pinned specs; product questions → the user.

## Month-end definition of done

1. v1-done clause satisfied (incl. human tails closed off or explicitly waived by the user).
2. Ratchet live with ≥1 repo genuinely unlocked and ≥1 relock-on-failure observed (or honest
   evidence why no repo earned it).
3. Cutover achieved (3 matching shadow sessions → conductor-driven loop) OR a documented
   mismatch trail showing exactly what blocks it.
4. Every close verify-by-artifact; scorecard Experience Log + model-bench rows current;
   decisions.md carries any new product calls; this spec updated where reality diverged.
