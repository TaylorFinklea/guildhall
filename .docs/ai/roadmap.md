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
- [x] `conductor-bursar` — SHIPPED (000fe3a, gpt-5.5; BursarClient trait+fake, 4/4 acceptance tests, 196/0).
- [x] `conductor-h23` — SHIPPED (ef2e812, gpt-5.5; ScanGap plumbing, 3 acceptance tests, 199/0).
- [x] Member milestones: `provenance-m5` (b049f07, ollama-minimax) · `hindsight-m4` (e4cbdce, ollama-minimax; audit clean, independent sweep concurred). `gauntlet-m4` (L) **CLOSED 07-08** — E2E bug-hunt arc (runs 1–8) caught+fixed **5 real product bugs**: `sr7` (prompt sandbox) → `43t` (read-ref allowlist) → `xqj` (dispatch timeout) → `qgo` (detector precision) → `qxi` (integrity watch path-granular + committed-escape hardening). Run 8 (post-qxi) completed the full harvest set (3 dispatched conjunctive-fail + 3 explicit skips, ledger appended, no integrity abort). `gauntlet-7mi` + `gauntlet-qxi` CLOSED. **Unblocks `gauntlet-m5`.**
- [x] `envoy-e2e-dryrun` — PASS (Sonnet dogfood; envelope validated; 4 skill findings → `envoy-hii`).
- [x] Clippy sweeps: `warden-vy1` (6660e28) · `provenance-ba9` (verified no-op, premise stale) · `gauntlet-s7h` (3595949).
- [x] 07-07 review + E2E findings — ALL CLOSED 07-07→08 by the fleet: `conductor-24e` (2ef0f30) · `1s8` (d624241) · `p9k` (6fa9158, clippy-green) · `bursar-g0n` (bc213a3) · `envoy-hii` (3de2908) · gauntlet `sr7`/`xqj`/`43t`/`qgo`/`7mi`.
- [x] **07-09 v1 finish + product demo** (spec+plan: `phases/v1-finish-demo-{spec,plan}.md`): OpenWiki **adopted** (c4b38bf — orientation-only per decisions.md [2026-07-09]; `conductor-1qh` reconciled/closed) · `gauntlet-m5` A/B config-delta report **CLOSED** (8c37580, gpt-5.5 senior/**L** — routing corrected, L exceeds minimax's M ceiling; 118/0 + clippy + hdeck-valid report; cost-controlled via fake exec, **no quota spent**) · **`demo/` product walkthrough SHIPPED** (3fec3aa) — all 8 members runnable on real substrate, read-only, no metered dispatch, honest maturity labels.
- [ ] **`gauntlet-nfx` (P1, lead-floor)** — golden-task harvest quality: `gauntlet lint golden-tasks` reports **6/6 defective** (every `verify_cmd` passes at its `base_commit` ⇒ verify cannot discriminate a fix from a no-op; only the judge carries quality signal). **Now blocks `gauntlet-m6`** (gauntlet's final v1 milestone): m6 patches `~/.claude/templates/tiers.md`, which drives ALL fleet routing, so its efficiency evidence must not rest on a compromised signal. Fix the harvest → then m6. *(The 7mi lint doing exactly its job; the harvest predates it.)*
- [ ] Human tails (user): guildhall-dogfood dashboard eyeball → human closes it; conductor-m3b live render; hindsight-m3 eyeball; bursar seven_day Keychain smoke. Stash drops (provenance-m2, hindsight-m2). **NEW: confirm/deny `conductor-frv` (gpt-5.5 ceiling M→L — evidence: 2 verified L closes; unblocks L-work leaving the Sonnet lane).**

### Next — Phase B: autonomy ladder (weeks 2–4)
- [x] `conductor-m6` ratchet **SHIPPED 07-08** (6698534, minimax-m3; ratchet.rs + `[ratchet]` config **junior/S/3** default per ADR; all 9 spec invariants tested, 228/0 clippy-green; orchestrator-verified — NO safety gap). Mechanism done; auto-dispatch activation gated by cutover — `cycle.rs` deliberately unwired (dry-run stays propose-only; wiring is a future one-liner via `triage_state_map`).
- [ ] `conductor-m5` triage-suggest backfill (deferred → 07-10, queue-hygiene ADR).
- [ ] `conductor-ilv` shadow protocol → cutover after 3 matching sessions (lead-floor). **Session 1 (07-07) NO-MATCH · session 2 (07-07) MATCH · session 3 (07-08) NO-MATCH → streak reset 0/3.** Routing matched on suite items; the reset is the whole-`~/git` scan + blanket-approval structural gap. Now bd-blocked-by `conductor-xa5`.
- [ ] **`conductor-xa5`** (NEW cutover blocker, lead-floor): `conductor dispatch` blanket-approval fires ALL proposals across the whole-`~/git` scan (07-09 dry-run: 43 repos, 103 proposals) — no per-item/suite scoping, so one suite bead can't be dispatched without firing the whole fleet. Blocks flipping the default loop to `conductor dispatch`. Fix options: per-item approval selection / scan-scoping / proposals-never-auto-fire-on-blanket-approval.
- [ ] **Roster-router refactor Phase 1** (user-approved spec 07-06, split 07-07): `conductor-d5j`→`r6p`→`xm9`→`3u3`/`o5k`, dep-chained, deferred → 07-10. Fixes shadow-mismatch classes (b) structurally-Claude carve-out + (d) routing opacity. Phases 2–4 stay next-month.
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
