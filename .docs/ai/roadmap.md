# Roadmap

> Durable goals and milestones. Updated when scope changes, not every session.

## Vision

Guildhall — a craft guild whose members are models: eight cooperating tools (Conductor, Warden, Hindsight, Envoy, Bursar, Provenance, Gauntlet, Foreman) that route, gate, record, audit, budget, evaluate, and compile the AI coding fleet's own work. Charter: `README.md`. Integration + v1-done: `phases/guildhall-integration-v1-spec.md`.

## Now / Next / Later

> Per-member backlogs live in each repo's beads (`bd -C ~/git/<member> ready`). This list tracks suite-level items only.

### Now
- [ ] Opus resumes execution per `current-state.md` § Resume plan (after the 2:10am CT Anthropic reset).
- [ ] Gap beads filed by Fable (2026-07-02) — pick up in build order:
  - `hindsight-m5-hd-beads-sources` (harness-deck + beads parsers; p3)
  - `warden-m6-dispatch-surface-coverage` (LEAD; the pi/agy enforcement-gap doc)
  - `conductor-guildhall-dogfood` (LEAD; the integration/vertical-slice proof)
  - `conductor-warden` (senior; wire warden into Conductor's own actions; v1.5)
- [ ] Redo the two limit-killed beads (stashes available): `hindsight-m2-pi-parser`, `provenance-m2`.
- [ ] `warden-rev` — LEAD adversarial review of the policy core (do like Conductor's rev1: mutation-check the invariants).

### Next
- [ ] Finish each member to its spec's final milestone (see build order); Conductor M3→M6 in parallel.

### Later
- [ ] The v1 integration proof: `conductor cycle --dry-run` over the real fleet (`conductor-guildhall-dogfood`).
- [ ] Post-v1 (Deferred sections): Envoy live transport; `hindsight why`; Warden pi/agy live-gating experiments; Foreman (built last).

## Build order

`warden → hindsight → envoy → bursar → provenance → gauntlet → foreman`; Conductor M3–M6 in parallel; Bursar floats earlier. See `decisions.md` 2026-07-01.

## Constraints

- Suite invariants in `README.md` are law (closed roster, tier_floor gate, fail-closed, never push, never chezmoi, one writer per repo, coverage gaps reported as gaps).
- Cross-repo deps are prose-only (bd has no cross-repo primitive) — honor the graph in `phases/guildhall-integration-v1-spec.md`.
- All work local + unpushed; the human applies anything destined for `~/.claude`/`~/.pi`/chezmoi.
