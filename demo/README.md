# Guildhall — product demo

A runnable, per-member walkthrough of the guild. Each step drives a **real**
member on **real** substrate (read-only / dry-run) — no metered model dispatch,
idempotent, safe to re-run.

```bash
demo/run.sh            # the whole vertical slice, in order
demo/run.sh conductor  # one member
demo/run.sh --build    # (re)build the member CLIs the demo needs
```

## What you're watching

Guildhall is *a craft guild whose members are models* — eight cooperating tools
that route, gate, record, audit, budget, evaluate, and compile an AI coding
fleet's own work. Two principles show up everywhere below:

- **Artifacts on disk are the event bus.** Members talk by writing well-formed
  files where the others already look (harness-deck reports, ledgers, sidecars,
  session JSONL). No brokers.
- **Exit codes are testimony; artifacts are evidence.** Every verifier judges by
  a real artifact (a new commit, a rendered report, a gate decision), and
  **coverage gaps are reported as gaps** — you'll see honest "unknown" and
  "deferred" in the output rather than faked success.

## The eight members

| # | Member | You run | What to look for | Maturity |
|---|---|---|---|---|
| 1 | **Conductor** — master of works | `conductor cycle --dry-run` | A whole-fleet plan: repos scanned, ready items triaged, each routed to a roster model, published to harness-deck. **This dry-run is the Guildhall v1 integration proof.** | live |
| 2 | **Bursar** — the treasury | `bursar status --json` | A provider quota/window ledger Conductor consults before metered dispatch. Note the honest per-provider status (`ok` / `error` / `unknown`) sourced from real usage endpoints + rollout scans. | live |
| 3 | **Warden** — inspecting officer | PreToolUse event → adapter | Three tool-use events classified: a benign Read → **allow**, a `curl … \| sh` → **ask** (gated), a malformed event → **deny** (fail-closed — invariant 3). | live |
| 4 | **Hindsight** — the inquest | `hindsight recap --since 24h` | A fleet flight-recorder report over the transcript substrate: tens of thousands of events + commits, and — honestly — the thousands of coverage gaps it can't yet reconstruct. | live |
| 5 | **Provenance** — hallmarks | `provenance annotate` + `query unreviewed-junior` | An authorship/exposure audit: git hunks correlated to the model that authored them (reusing Hindsight's ingestion, never forking parsers), with junior-tier hunks lacking a later senior touch flagged. Read-only on the repo; writes its sidecar to `~/.local/state/provenance/`. | live |
| 6 | **Gauntlet** — masterpiece trials | `gauntlet lint` + recorded replay + A/B report | Eval CI for the agent stack. The discrimination lint honestly flags non-discriminating golden tasks; a recorded worktree-sandboxed replay shows conjunctive `verify AND judge` verdicts; the M5 A/B (config-delta) report compares a baseline vs a delta config. *No fresh metered run.* | live |
| 7 | **Envoy** — the emissary | `validate-envelope.sh <fixtures>` | The agent-consult primitive's fail-closed envelope validator (13 pinned checks): a golden envelope **passes**, a broken one is **rejected**. Live transport is a deliberate v1 non-goal. | dry-run |
| 8 | **Foreman** — the works office | `bd -C ~/git/foreman list` | Spec-to-backlog compiler, built LAST in the guild order and **ADR-deferred to 2026-08** — so it's design-only today. Shown honestly: its v1 spec + seeded bead DAG, not a faked run. | spec-only |

## Notes

- **No metered dispatch.** The demo reads existing artifacts and runs read-only /
  dry-run paths only. The Gauntlet step surfaces a *recorded* replay + the
  already-generated A/B report rather than launching new worker dispatches.
- **Order** follows the v1 vertical slice (`guildhall-integration-v1-spec.md`):
  Conductor plans → Bursar budgets → Warden gates → Hindsight reconstructs →
  Provenance annotates → Gauntlet evaluates → Envoy consults → Foreman compiles.
- **First run** builds three member CLIs (Hindsight/Provenance/Bursar) and the
  Warden adapter; subsequent runs reuse them.
