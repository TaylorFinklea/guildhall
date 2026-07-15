# Roadmap

> Durable goals and milestones. Updated when scope changes, not every session.

## Vision

The runtime product is now four Unix-style tools: Conductor runs explicit verified job loops; Bursar owns roster/availability; Hindsight owns evidence, attribution, and scorecards; Warden reads events and emits advisory findings. Provenance, Gauntlet, Envoy, and Foreman migrate into those surfaces; Guildhall preserves migration history and then archives. Approved design: `phases/conductor-core-consolidation-spec.md`.

## Now / Next / Later

> Per-member backlogs live in each repo's beads (`bd -C ~/git/<member> ready`). This list tracks suite-level items only.

> **MONTH PLAN (2026-07)**: `phases/2026-07-autonomy-month-spec.md` + the four `[2026-07-03]`
> ADRs govern this section. Sessions 2026-07-02→03 closed 27 beads (exec #1–#2d + review;
> details in bd close reasons + git history — not restated here).

### Now — Conductor core consolidation (approved 2026-07-14)

- [x] Architecture, execution plan, and reviewable 26-Bead generator authored:
      `phases/conductor-core-consolidation-{spec,plan}.md` and
      `phases/bd-create-conductor-core-consolidation.sh`.
- [x] Fresh Lead Task 0: Conductor adversarial review landed at `055692e`; the 26-Bead
      generator was applied, obsolete goals reconciled, and all nine queues pass lint and
      dependency-cycle checks.
- [ ] Wave 0 correctness (started: `provenance-5fu` → `bc2db7b`; `hindsight-d96` → `8ad0446`): audit
      attribution/source/envelope P0s, Conductor identity/lease/resume, adversarial injection
      hardening, Bursar fail-closed status, corrected migration corpora.
- [ ] Waves 1–3: Bursar roster → Hindsight store/events → Conductor loop/jobs → scorecards,
      attribution, Warden findings, consult/Arena/eval folds.
- [ ] Wave 4 human-controlled tails: chezmoi Ralph/skills/LaunchAgent cutover and private
      scorecard-state migration. Never version the Hindsight SQLite database.
- [ ] Final no-spend four-tool vertical slice; archive Guildhall only after all ten spec gates pass.

### Now — Phase A: close v1 (~week 1)
- [x] **GPT-5.6 roster rollout** — Sol/Architect=`max`, Terra/Lead=`xhigh`, Luna=`medium` Junior / `high` Senior; direct Codex backend, per-row effort, Arena/Ralph propagation, and scorecard drift/digest alignment. Landed in Conductor `e4aeda9` + chezmoi scorecard `68d76d3`; 236+1 tests, clippy, installed `conductor` config/drift, Ralph isolated preflights, digest + harness-deck validation, and the read-only Guildhall demo passed. Spec/report: `phases/gpt56-roster-rollout-{spec,report}.md`.
- [ ] **HUMAN**: review and apply the intended chezmoi source changes for GPT-5.5 retirement. Do not wholesale-apply while unrelated HOME drift remains.
- [x] `conductor-review` — **the v1 gate SHIPPED** (c01377d, gpt-5.5, verified; 153 tests + clippy green).
- [x] `conductor-bursar` — SHIPPED (000fe3a, gpt-5.5; BursarClient trait+fake, 4/4 acceptance tests, 196/0).
- [x] `conductor-h23` — SHIPPED (ef2e812, gpt-5.5; ScanGap plumbing, 3 acceptance tests, 199/0).
- [x] Member milestones: `provenance-m5` (b049f07, ollama-minimax) · `hindsight-m4` (e4cbdce, ollama-minimax; audit clean, independent sweep concurred). `gauntlet-m4` (L) **CLOSED 07-08** — E2E bug-hunt arc (runs 1–8) caught+fixed **5 real product bugs**: `sr7` (prompt sandbox) → `43t` (read-ref allowlist) → `xqj` (dispatch timeout) → `qgo` (detector precision) → `qxi` (integrity watch path-granular + committed-escape hardening). Run 8 (post-qxi) completed the full harvest set (3 dispatched conjunctive-fail + 3 explicit skips, ledger appended, no integrity abort). `gauntlet-7mi` + `gauntlet-qxi` CLOSED. **Unblocks `gauntlet-m5`.**
- [x] `envoy-e2e-dryrun` — PASS (Sonnet dogfood; envelope validated; 4 skill findings → `envoy-hii`).
- [x] Clippy sweeps: `warden-vy1` (6660e28) · `provenance-ba9` (verified no-op, premise stale) · `gauntlet-s7h` (3595949).
- [x] 07-07 review + E2E findings — ALL CLOSED 07-07→08 by the fleet: `conductor-24e` (2ef0f30) · `1s8` (d624241) · `p9k` (6fa9158, clippy-green) · `bursar-g0n` (bc213a3) · `envoy-hii` (3de2908) · gauntlet `sr7`/`xqj`/`43t`/`qgo`/`7mi`.
- [x] **07-09 v1 finish + product demo** (spec+plan: `phases/v1-finish-demo-{spec,plan}.md`): OpenWiki **adopted** (c4b38bf — orientation-only per decisions.md [2026-07-09]; `conductor-1qh` reconciled/closed) · `gauntlet-m5` A/B config-delta report **CLOSED** (8c37580, gpt-5.5 senior/**L** — routing corrected, L exceeds minimax's M ceiling; 118/0 + clippy + hdeck-valid report; cost-controlled via fake exec, **no quota spent**) · **`demo/` product walkthrough SHIPPED** (3fec3aa) — all 8 members runnable on real substrate, read-only, no metered dispatch, honest maturity labels.
- [x] **`gauntlet-nfx` CLOSED 07-09** (7521a9f, Opus/Lead) — golden-task harvest repaired: all 6 gates now FAIL at `base_commit` and PASS at their reference commit. `gauntlet lint`: **defective=0 failing=6 errored=0, exit 0**. Gates assert ≥1 *passing* test in a structural scope the task must implement (module path / name prefix — never an exact reference test name), not file existence: 3 of 4 Rust base commits already ship the deliverable as a stub, and warden's partial `classify.rs` even ships 2 passing tests. Verified by worktree checkout at both commits (base→ref passing tests: conductor 0→21, hindsight 0→14, provenance 0→6, warden 0→11; envoy 1→0 exit). ADR in gauntlet `decisions.md`. **Unblocks `gauntlet-m6`.**
- [x] **`gauntlet-m6` CLOSED 07-09** (Opus/Lead, **zero metered dispatch**) — **gauntlet v1 milestones now complete** (m3→m4→m5→m6). Efficiency ratings derived *observationally* from the pi agent-log substrate (702 runs / 776 files), size-normalised by `$/1k output tok` + `output tok/s`, quality parity gated on the bench ledger. Proposed patch `gauntlet/out/tiers-efficiency-patch.diff` (3 lines: MiniMax `lean (cost unconfirmed)`; Qwen-Max + GLM-5.2 `lean (confirmed)`) applies cleanly; `tiers.md` never written (byte-identical). GPT-5.5's proposed rating was withdrawn when the lane retired 07-10. harness-deck report `gauntlet/m6-efficiency-20260709` retains the original evidence. **Method deviation (ADR)**: m6's stated A/B method was unusable — `ab.rs::from_replay` hardcodes `token_cost_usd: 0.0`, so a real replay never captures cost and a fresh sweep would have fabricated the cost axis → `gauntlet-90e`.
- [ ] **HUMAN**: approve/reject the remaining 3-line `gauntlet/out/tiers-efficiency-patch.diff` (MiniMax/Qwen-Max/GLM-5.2 only; the historical harness-deck approval block includes the withdrawn GPT-5.5 proposal).
- [x] **`gauntlet-90e` CLOSED 07-10** (9bd1b91 + aa48729) — replay captures real pi-log cost and fails closed (`unknown`, never zero) for unreported lanes; correlation accepts the provider-bare model ID and normalizes macOS `/private` cwd paths. 138/0 + clippy. A controlled same-task A/B is now mechanically possible; opencode-go/ollama-cloud cost remains unreported.
- [ ] Human tails (user): guildhall-dogfood dashboard eyeball → human closes it; conductor-m3b live render; hindsight-m3 eyeball; bursar seven_day Keychain smoke. Stash drops (provenance-m2, hindsight-m2). `conductor-frv` is obsolete: GPT-5.5 retired 07-10.

### Now — Phase A2: suite composability (NEW thrust, user-authorized 2026-07-13)

Spec: `phases/unix-composability-spec.md`. Guide: `USAGE.md`. ADRs: decisions.md
`[2026-07-13]` ×3 (charter amendment · pipe-not-crate · month-focus amendment).
Adversarially reviewed by glm-5.2 / qwen3.7-max / minimax-m3 — the panel killed the
first draft's rubric and rescued provenance from a wrongful finding.

- [x] **Slice 1/2/3 SHIPPED 2026-07-13** (conductor `b3631a0`, bursar `1fab043`, warden
      `b7a6205`, hindsight `2d80c5e`, provenance `e06d6df`, gauntlet `52828b9`). Guardrails
      guard, six binaries on PATH, `hindsight events | gauntlet cost --stdin` +
      `provenance annotate --events -` compose. See current-state.md + decisions.md `[2026-07-13]`.
- [ ] **HUMAN**: re-auth bursar's Anthropic OAuth token — live `HTTP 401`, lane is blind.

### Now — Phase A3: post-review stabilization (2026-07-14, breadth-first)

Full suite adversarial review (Fable + 6 Sonnet discovery + GPT-5.6 Sol/Terra ×5 + glm-5.2 ×3,
every P0/P1 independently verified, several by binary repro). ADRs: decisions.md `[2026-07-14]` ×4.
**51 beads filed across all members** with tier_floor/complexity/verify_cmd metadata.
Root cause (guildhall-y10/6mc): pure logic clean, every integration SEAM fails open + untested.

- [ ] **Lead thrust = BREADTH STABILIZE** (user 2026-07-14): sweep the P1/P2 fixes across all
      members. `bd -C ~/git/<member> ready` per repo. The audit-pipe-correctness items ride
      inside this sweep at high priority (must-be-correct, user 2026-07-14).
- [ ] **Audit pipe must be correct**: provenance `provenance-5fu` closed at `bc2db7b`;
      hindsight `hindsight-d96` closed at `8ad0446`; suite `guildhall-y10` remains
      (schema+artifact envelope — the pipe is bare JSON, P0). False attribution > no attribution.
- [ ] **Warden → read-only Hindsight filter** (supersedes the same-day shadow-hook direction):
      `hindsight events | warden inspect` emits advisory findings; no hook install or enforcement.
- [ ] **conductor injection hardening** (glm-5.2 fresh-eyes): `conductor-zg9` (reviewer prompt
      unfenced → bead text can force verdict:ship) + `conductor-5tg` (stored injection into
      comments/ledger/verifier). Matters even under supervised autonomy.

### Next — Phase B: SUPERVISED autonomy ladder (retargeted 2026-07-14 — NOT unattended)

> **Superseded as a product direction by the Conductor-core ADR above.** Preserve
> `conductor-1i9`/`vnu`/`9uk` as explicit-loop prerequisites. Retire ratchet wiring,
> shadow cutover, and automatic triage backfill instead of completing this ladder.

> **Target changed** (decisions.md `[2026-07-14]`): the few-weeks goal is **supervised autonomy**
> (batch-approve bounded plan → auto-execute with per-item resume → human reviews after), NOT the
> default unattended loop. The ratchet stays **observe-only**. Unattended junior/S is a later
> canary, only after warden-enforcement + resumable execution + exclusive repo lease + trustworthy
> verification + provider-fail-closed all have fresh evidence. Sequencing = Sol's 8 gated steps (ADR).

- [ ] **`conductor-1i9` (P0, LINCHPIN)**: worker success is identity-free (`dispatch.rs:350-352`
      counts ANY new HEAD, not the worker's) + no repo lease → the ratchet's "clean session"
      signal is forgeable by any concurrent commit (already happened once). Fix: identity-checked
      success + exclusive lease/worktree. **Blocks the whole ladder.**
- [ ] **`conductor-vnu` (P0)** + **`conductor-9uk` (P0)**: no resume/reclaim (crash → bead claimed
      forever) + fail-stop loop (one item's error aborts the whole plan). Resumable per-item state
      machine is Sol's step 4, a hard prerequisite for batch autonomy.
- [ ] **`conductor-ldz`**: `SpendCautiously` is a no-op (only `Defer` gates) — align with
      `provider-trust-integration-spec` (uncertain → Defer). `conductor-0ma` (percent bounds check).
- [x] `conductor-m6` ratchet mechanism built (6698534) — but **UNWIRED** (`conductor-jx2`): no
      non-dry-run cycle calls it. Stays observe-only per the retarget; wiring is gated by the above.
- [ ] `conductor-m5` triage-suggest backfill (deferred → 07-10, queue-hygiene ADR).
- [ ] `conductor-ilv` shadow protocol → **superseded framing**: cutover is no longer "3 matching
      sessions → default unattended loop" but "supervised autonomy solid, ratchet observe-only."
      Still bd-blocked-by `conductor-xa5`.
- [ ] **`conductor-xa5`** (cutover blocker, lead-floor): blanket-approval fires ALL proposals across
      the whole-`~/git` scan — no per-item/suite scoping. Now also gated by the supervised-autonomy
      bounded-plan work (Sol's step 3: immutable bounded plan + drift rejection).
- [ ] **Roster-router refactor Phase 1**: `conductor-d5j`→`r6p`→`xm9`→`3u3`/`o5k`, dep-chained.
- [ ] Post-supervised: revisit unattended junior/S canary — only with the [2026-07-14] evidence gates met.
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
