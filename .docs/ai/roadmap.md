# Roadmap

> Durable goals and milestones. Updated when scope changes, not every session.

## Vision

Guildhall — a craft guild whose members are models: eight cooperating tools (Conductor, Warden, Hindsight, Envoy, Bursar, Provenance, Gauntlet, Foreman) that route, gate, record, audit, budget, evaluate, and compile the AI coding fleet's own work. Charter: `README.md`. Integration + v1-done: `phases/guildhall-integration-v1-spec.md`. Operations: `phases/orchestration-runbook.md`.

## Now / Next / Later

> Per-member backlogs live in each repo's beads (`bd -C ~/git/<member> ready`). This list tracks suite-level items only.

### Now
- [ ] Opus executes per `current-state.md` § Resume plan (check provider limits LIVE at session start — printed reset times are stale by design).
- [x] `warden-rev` — LEAD review done (exec #1); `warden-m3` unblocked + closed.
- [x] Redo the two limit-killed beads — done (exec #1). NOTE: the 2 now-superseded stashes (`hindsight-m2-pi-parser`, `provenance-m2`) await a HUMAN `git stash drop` — agent stash-drop is blocked by the safety classifier.
- [x] `warden-m6-dispatch-surface-coverage` — done (exec #2, a5689fc): honest verdict ZERO surfaces live-gated today + pi-dispatch-wrapper sketch.
- [x] `hindsight-m3` (exec #2) → unblocks `hindsight-m5-hd-beads-sources`; `conductor-m3b` (exec #2) → unblocks `conductor-guildhall-dogfood`.
- [x] `gauntlet-m3-harvest` — done (exec #2b, 7091425): 6 golden tasks via hindsight's parser, all smoke-pass.
- [x] `conductor-guildhall-dogfood` — objective proof DONE (exec #2b) + found/fixed a silent-failure bug (f21c2c2); OPEN pending the human dashboard-render eyeball (then human `bd close`).
- [x] exec #2c (gpt-5.5): `conductor-m4c` (L keystone), `bursar-m4-cli`, `hindsight-m4-guardian-agy` — closed & verified.
- [ ] **STILL PAUSED (fleet re-down 2026-07-03)** — resume on gpt-5.5 next 5h reset (poller) or opencode-go weekly ~07-05: `hindsight-m5-hd-beads-sources` (M, +green repo clippy gate) and `provenance-m4` (L). Then `conductor-review` (P1, **gates v1**, now unblocked by m4c). `conductor-warden` deferred (v1.5).
- [ ] `conductor-h23` (NEW, exec #2b) — scan.rs: surface bd-ready parse failures instead of silently emptying a repo.
- [ ] `envoy-e2e-dryrun` — HELD: needs the envoy SKILL run in a Claude harness against a real repo (dogfood) + `validate-envelope.sh`; do with Sonnet/human, not a pi worker.

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
