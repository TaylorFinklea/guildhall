# Roadmap

> Durable goals and milestones. Updated when scope changes, not every session.

## Vision

Guildhall — a craft guild whose members are models: eight cooperating tools (Conductor, Warden, Hindsight, Envoy, Bursar, Provenance, Gauntlet, Foreman) that route, gate, record, audit, budget, evaluate, and compile the AI coding fleet's own work. Charter: `README.md`. Integration + v1-done: `phases/guildhall-integration-v1-spec.md`. Operations: `phases/orchestration-runbook.md`.

## Now / Next / Later

> Per-member backlogs live in each repo's beads (`bd -C ~/git/<member> ready`). This list tracks suite-level items only.

### Now
- [ ] Opus executes per `current-state.md` § Resume plan (check provider limits LIVE at session start — printed reset times are stale by design).
- [ ] `warden-rev` — LEAD adversarial review of the policy core (mutation-check the invariants, like Conductor's rev1). `warden-m3` is bd-blocked on it; do it early.
- [ ] Redo the two limit-killed beads (stashes available): `hindsight-m2-pi-parser` (orphan-file landmine — see bead comment), `provenance-m2` (pop + build on).
- [ ] Gap beads (Fable 2026-07-02), now properly gated in bd:
  - `hindsight-m5-hd-beads-sources` (p3; blocked on hindsight-m3)
  - `warden-m6-dispatch-surface-coverage` (LEAD; ready)
  - `conductor-guildhall-dogfood` (LEAD; blocked on conductor-m3b)
  - `conductor-warden` (deferred — v1.5)

### Next
- [ ] Finish each member to its spec's final milestone (build order); Conductor M3→M4→(m5/m6/review) in parallel. `conductor-review` is P1 and **gates v1** (decisions.md 2026-07-02).

### Later
- [ ] The v1 integration proof: `conductor cycle --dry-run` over the real fleet (`conductor-guildhall-dogfood`).
- [ ] Un-defer foreman (all 6 beads bd-deferred) when the other six members ship v1.
- [ ] Post-v1 (Deferred sections): Envoy live transport; `hindsight why`; Warden pi/agy live-gating experiments.

## Build order

`warden → hindsight → envoy → bursar → provenance → gauntlet → foreman`; Conductor M3–M6 in parallel; Bursar floats earlier. See `decisions.md` 2026-07-01.

## Constraints

- Suite invariants in `README.md` are law (closed roster, tier_floor gate, fail-closed, never push, never chezmoi, one writer per repo, coverage gaps reported as gaps).
- Budget caps ride with the plan (user-approved 2026-07-02 "Moderate" — runbook § Budget caps).
- Cross-repo deps are prose-only (bd has no cross-repo primitive) — honor the graph in `phases/guildhall-integration-v1-spec.md`. Within-repo gates ARE now encoded in bd (runbook § Sequencing gates).
- All work local + unpushed; the human applies anything destined for `~/.claude`/`~/.pi`/chezmoi.
