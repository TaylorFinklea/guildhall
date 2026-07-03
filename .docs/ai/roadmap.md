# Roadmap

> Durable goals and milestones. Updated when scope changes, not every session.

## Vision

Guildhall — a craft guild whose members are models: eight cooperating tools (Conductor, Warden, Hindsight, Envoy, Bursar, Provenance, Gauntlet, Foreman) that route, gate, record, audit, budget, evaluate, and compile the AI coding fleet's own work. Charter: `README.md`. Integration + v1-done: `phases/guildhall-integration-v1-spec.md`. Operations: `phases/orchestration-runbook.md`.

## Now / Next / Later

> Per-member backlogs live in each repo's beads (`bd -C ~/git/<member> ready`). This list tracks suite-level items only.

> **MONTH PLAN (2026-07)**: `phases/2026-07-autonomy-month-spec.md` + the four `[2026-07-03]`
> ADRs govern this section. Sessions 2026-07-02→03 closed 27 beads (exec #1–#2d + review;
> details in bd close reasons + git history — not restated here).

### Now — Phase A: close v1 (~week 1)
- [x] `conductor-review` — **the v1 gate SHIPPED** (c01377d, gpt-5.5, verified; 153 tests + clippy green).
- [ ] `conductor-bursar` (P1, **v1-GATING** per integration spec step 2) — fleet.
- [ ] `conductor-h23` (P1, autonomy precondition — no silent-empty scans) — fleet.
- [ ] Member final milestones: `provenance-m5` (query.rs), `gauntlet-m4-replay-verify-judge` (L), `hindsight-m4-fixtures-hardening` (P3) — fleet.
- [ ] `envoy-e2e-dryrun` — **Sonnet** (structurally-Claude carve-out, see its bd comment).
- [ ] Clippy sweeps: `warden-vy1`, `provenance-ba9`, `gauntlet-s7h` (S) — fleet.
- [ ] Human tails (user): guildhall-dogfood dashboard eyeball → human closes it; conductor-m3b live render; hindsight-m3 eyeball; bursar seven_day Keychain smoke. Stash drops (provenance-m2, hindsight-m2).

### Next — Phase B: autonomy ladder (weeks 2–4)
- [ ] `conductor-m6` ratchet (mechanism per spec; **config default junior/S** per ADR — see bd comment).
- [ ] `conductor-m5` triage-suggest backfill.
- [ ] `conductor-ilv` shadow protocol → cutover after 3 matching sessions (lead-floor; the orchestrator's own bead).
- [ ] Post-cutover: ratchet unlock observed in production; `conductor dispatch` becomes the default loop.

### Later (NEXT month's candidates — do NOT pull forward; ADR-locked out of scope)
- [ ] Warden pi-dispatch-wrapper (`warden-44n`, P3 capture) + agy live-gating experiments; `conductor-warden` (v1.5).
- [ ] Envoy live transport; `hindsight why`.
- [ ] Un-defer foreman (all 6 beads) once the autonomy ladder holds in production.
- [ ] Autonomy-config widening toward the spec ceiling ({senior,junior}/≤M) — human decision, ratchet-evidence-backed.

## Build order

`warden → hindsight → envoy → bursar → provenance → gauntlet → foreman`; Conductor M3–M6 in parallel; Bursar floats earlier. See `decisions.md` 2026-07-01.

## Constraints

- Suite invariants in `README.md` are law (closed roster, tier_floor gate, fail-closed, never push, never chezmoi, one writer per repo, coverage gaps reported as gaps).
- Budget caps ride with the plan (user-approved 2026-07-02 "Moderate" — runbook § Budget caps).
- Cross-repo deps are prose-only (bd has no cross-repo primitive) — honor the graph in `phases/guildhall-integration-v1-spec.md`. Within-repo gates ARE now encoded in bd (runbook § Sequencing gates).
- All work local + unpushed; the human applies anything destined for `~/.claude`/`~/.pi`/chezmoi.
