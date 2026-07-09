# Guildhall v1 finish + product demo — spec

**Status**: design approved (2026-07-09, user). Opus owns execution.
**Owner**: Opus (Lead). Senior/Junior implementation dispatched per tier routing.
**Supersedes nothing**; complements `guildhall-integration-v1-spec.md` (the v1-done
definition) and the `2026-07-autonomy-month-spec.md` (which deferred Foreman).

## Goal

Finish the bounded remaining Guildhall **v1** work, adopt **OpenWiki**, and build a
runnable **per-member demo harness** so the user can drive each member and watch it
work on real substrate — honest about maturity gaps per the charter's "coverage gaps
are reported as gaps."

## Decisions locked (2026-07-09, user — via brainstorming Q&A)

1. **Demo form** = per-member walkthrough (a runnable `demo/` harness + narrated doc),
   NOT a heavy live-vertical-slice or a dashboard-only capture.
2. **Finish scope** = full v1 finish, **honoring ADR [2026-07-03]**: Foreman stays
   deferred (an honest "spec-only" panel in the demo). Phase-B items are out of scope.
3. **OpenWiki** = adopt for guildhall now; running it on the 7 member repos is an
   optional stretch (each `--init` is a metered pass), not required.
4. **Demo location** = `guildhall/demo/` (the suite meta-repo is the natural home).
5. **gauntlet m5/m6** dispatched to a senior/M model (minimax-m3), orchestrator-verified
   — same pattern as the 2026-07-08 session.

## Context: why "full v1 finish" is bounded

v1-done (per `guildhall-integration-v1-spec.md`) = the Conductor dry-run cycle +
Bursar budget + Conductor review-gate work end to end, AND every member has reached
its own spec's final milestone with verify passing. Current state (2026-07-09):

- **5 members complete** (zero non-deferred open beads): Hindsight (8 closed),
  Provenance (8), Bursar (6), Envoy (6), Warden (10 closed; only 2 v1.5 beads deferred).
- **Conductor** through m6 (35 closed). All still-open Conductor work
  (roster-router chain, conductor-m5, cutover/xa5, 1qh) is **Phase-B — beyond v1-done.**
- **Gauntlet**: `m5-ab-report` (open) + `m6-efficiency-workload` (blocked-by m5) —
  the efficiency-ratings milestone = step 6 of the vertical slice = genuinely v1.
- **Foreman**: 0 code (5 blocked + 7 deferred beads), ADR-deferred to next month.

So the only genuine v1 gaps are **gauntlet m5+m6** and **closing the integration proof**.

## Sub-project A — Adopt OpenWiki

**Scope**: adopt the `openwiki/` reference docs the user already generated on guildhall
(currently uncommitted, alongside an uncommitted `AGENTS.md` pointer).

**Steps**:
1. Review `openwiki/{quickstart,architecture,workflows,operations}.md` for accuracy
   against the charter/current-state (fix anything materially wrong; light touch).
2. Keychain-safety check (the `conductor-1qh` verify_cmd):
   `test -d openwiki && ! test -s "$HOME/.openwiki/.env" && ! git grep -qIE "(sk-[A-Za-z0-9]{20,}|_API_KEY=)" -- openwiki`.
3. Commit `openwiki/` + the `AGENTS.md` pointer to guildhall (surgical, explicit paths —
   the user has other uncommitted work in this repo; never sweep it in).
4. Write an **adopt ADR** in guildhall `.docs/ai/decisions.md` (context: pilot, decision:
   adopt for orientation only — not source-of-truth for live state/decisions).
5. Reconcile `conductor-1qh` (scoped to *harness-conductor*, but the user ran it on
   *guildhall*): close it as "adopted on guildhall instead" OR repurpose to the optional
   member-repo runs. Record the call.

**Acceptance**: `openwiki/` + AGENTS.md pointer committed; adopt ADR present; keychain
check passes; `conductor-1qh` reconciled.
**Verify**: the keychain one-liner above exits 0; `git -C guildhall log` shows the adopt
commit; `grep -q OpenWiki .docs/ai/decisions.md`.

## Sub-project B — Finish v1

**gauntlet-m5-ab-report** (senior/M): follow the bead exactly (ab.rs + deck.rs,
`gauntlet run --config-delta`). Dispatch → minimax-m3 (ollama-cloud lane). Worker makes
one commit; orchestrator independently re-verifies (`cargo test` + `cargo clippy
--all-targets -- -D warnings` green) and code-reviews before `bd close`.

**gauntlet-m6-efficiency-workload** (P1, senior/M, blocked-by m5): follow the bead
(evidence-backed efficiency ratings → a **proposed** `tiers.md` patch handed to the human,
never applied). Dispatch after m5 closes; same verify+review+close discipline. The
tiers.md patch is a pending-human handoff (never applied by the fleet).

**conductor-guildhall-dogfood** (the integration proof, lead-floor, human-verify):
folded into the demo. The Conductor demo step re-runs `conductor cycle --dry-run` over the
real fleet and publishes the plan to harness-deck; that IS the integration proof, and the
user's eyeball during the demo is the human-verify that closes the bead.

**Out of scope (do NOT touch)**: Foreman (deferred), roster-router chain (deferred 07-10),
conductor-m5 (deferred), cutover/xa5, warden v1.5 beads, envoy live transport.

**Acceptance**: gauntlet m5+m6 closed with verified artifacts (tests+clippy green, one
commit each, orchestrator-reviewed); integration-proof dry-run renders + is human-closed.
**Verify**: `bd -C ~/git/gauntlet list --status=open` shows m5/m6 closed;
`cargo test` green in gauntlet at the new HEAD; dogfood report renders on harness-deck.

## Sub-project C — The demo harness (`guildhall/demo/`)

**Structure**:
- `demo/run.sh <member>|all` — builds the 3 unbuilt CLIs (hindsight/provenance/bursar)
  on first run, then runs each member's primary function on **real** substrate,
  read-only/dry-run, printing observable output. Idempotent; safe to re-run.
- `demo/README.md` — the narrated walkthrough: per member, what it does, the exact
  command, what to look for in the output, and how it fits the substrate/vertical-slice
  story. Each step is labeled with its **maturity**: `live` / `dry-run` / `lib-via-tests`
  / `spec-only`.
- Optional capstone: a harness-deck report aggregating the run's outputs (the demo's own
  output is artifacts — dogfoods the substrate principle).

**Per-member plan** (exact CLI flags for the buildable CLIs + the Warden driver shape are
**codebase-derived — discover them from each member's `<name>-v1-spec.md` + `--help`
during implementation**; mirror the integration-spec vertical-slice step descriptions.
Do NOT hardcode unverified flags in this spec):

| # | Member | Demo step (primary function) | Maturity |
|---|---|---|---|
| 1 | Conductor | `conductor cycle --dry-run` → fleet plan to harness-deck (centerpiece = integration proof) | live |
| 2 | Bursar | `bursar status --json` → provider-window ledger (feeds Conductor budgeting) | live (build) |
| 3 | Warden | tiny driver (or its test suite) showing a policy gate decision (allow vs gate) — lib-only | lib-via-tests |
| 4 | Hindsight | `hindsight recap --since <t>` → flight-recorder report over real transcripts | live (build) |
| 5 | Provenance | `provenance annotate` on a real repo → authorship/exposure audit (consumes Hindsight ingestion) | live (build) |
| 6 | Gauntlet | `gauntlet lint` + a cached/tiny run — **no fresh metered gpt-5.5 dispatch in the default demo** | live |
| 7 | Envoy | `scripts/validate-envelope.sh` on the golden fixtures → consult envelope round-trip (dry-run; live transport is a v1 non-goal) | dry-run |
| 8 | Foreman | honest panel: "spec-only, deferred to 2026-08 per ADR" + shows its v1 spec + seeded bead DAG | spec-only |

**Honesty rule**: every step states its maturity; no step fakes output. Foreman shows its
DESIGN (spec + bead DAG), not a fake run.

**Acceptance**: `bash demo/run.sh all` runs all 8 steps producing observable output or an
honest maturity label; `demo/README.md` lets a human reproduce each; committed to
guildhall; default run performs **no metered dispatch**.
**Verify**: `bash demo/run.sh all` exits 0 and prints a labeled section per member; a
second run is idempotent.

## Sequence

**A (OpenWiki, quick)** → **B (finish v1: gauntlet m5 → m6, dogfood)** → **C (demo)**.
B's gauntlet work should land before C so the Gauntlet demo step can reference the real
m5/m6 capabilities. A is independent and improves the orientation docs C leans on.

## Non-goals

Foreman build (any); Phase-B (roster-router, conductor-m5, cutover, xa5); Warden/Envoy/
Hindsight v1.5 items; Envoy live transport; applying the tiers.md patch (human handoff);
member-repo OpenWiki runs (optional stretch only); any fresh metered dispatch inside the
default `demo/run.sh all`.

## Risks / caveats

- **User's uncommitted work in guildhall** (`AGENTS.md`, `openwiki/`): sub-project A
  adopts these deliberately; all other guildhall commits stay surgical (explicit paths).
  One-writer-per-repo: coordinate if the user's OpenWiki tooling is still writing here.
- **Metered dispatches**: gauntlet m5/m6 (minimax-m3) cost real quota; the demo's default
  run must not add more.
- **Human-verify tail**: the integration proof (dogfood) closes on the user's eyeball
  during the demo, not autonomously.
- **Codebase-derived demo commands**: the exact hindsight/provenance/bursar flags and the
  Warden driver are discovered at implementation time from each member's spec — not pinned
  here — to avoid confidently-wrong invocations.
