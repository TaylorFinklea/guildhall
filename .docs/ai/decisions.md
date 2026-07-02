# Decisions

> Architecture decision records. Append-only — one entry per decision.

## [2026-07-01] The substrate principle: artifacts on disk are the event bus

**Context**: Eight guild members need to interoperate; the temptation is a broker/daemon.
**Decision**: Members communicate exclusively through durable files in locations the others already read (harness-deck reports, transcript substrate per the ingestion event model, envoy envelope files, beads, git). New IPC requires a charter amendment.
**Alternatives considered**: agent-bus (exists on Scadrial, broken end-to-end per memory), a new message daemon, MCP everywhere.
**Rationale**: Recon proved the substrate already exists and correlates (see ingestion-event-model.md); files survive context clears, crashes, and harness swaps; every additional live service is another thing Warden can't gate and Hindsight can't replay.

## [2026-07-01] Ingestion lives in hindsight first; provenance extracts, never forks

**Context**: hindsight and provenance both parse the same four transcript stores.
**Decision**: hindsight owns the parsers in v1; when provenance needs them they are extracted to a shared lib in one move. Parser forks are prohibited.
**Rationale**: The stores are quirky (pi's double-dash slugs, Codex subagent threads, agy glog); two divergent parsers would disagree about ground truth — fatal for an audit tool.

## [2026-07-01] Exit codes are testimony; artifacts are evidence

**Context**: agy exits 0 after quota-exhausted no-op runs (confirmed root cause, cli logs 2026-07-01); orchestra exit 2 conflates usage error with wedged endpoint.
**Decision**: Every guild verifier judges completion by artifact (new commit, file present, expected log line) — exit codes are corroborating, never sufficient. Backend-specific no-op detectors (agy: grep invocation log for RESOURCE_EXHAUSTED) are part of dispatch contracts.
**Rationale**: Learned in production during Conductor cycle 1 — a 0-byte "success" cost two dispatch attempts before diagnosis.

## [2026-07-01] Warden gates unknown tools (reverses guardian's pass-through)

**Context**: pi guardian passes unrecognized/custom tool names ungated (classify.ts:134-135) — its one fail-open hole.
**Decision**: Warden's host-agnostic core defaults unknown tool names to the gated path (prompt interactively, block headless); host adapters may register known-safe tool maps.
**Rationale**: Fail-closed invariant; a new tool name is exactly when policy knowledge is weakest.

## [2026-07-01] Build order: warden → hindsight → envoy → bursar → provenance → gauntlet → foreman

**Context**: Default order proposed in the bootstrap prompt; recon asked to re-derive.
**Decision**: Keep the default. bursar noted as float-anywhere (smallest, nothing blocks on it); foreman explicitly last.
**Rationale**: Fleet dispatches today with compensating-controls-only safety (agy hooks unconfirmed) → warden first. Everything downstream reads the substrate → hindsight second. foreman's product is the crystallization of Lead-by-hand spec sessions — building it before the pattern is proven bakes in guesses.

## [2026-07-01] agy headless posture pending two experiments

**Context**: agy recon found unconfirmed native hooks machinery (PreToolHooks, hooks.json, `plugin import claude`) and a `--sandbox`/`strict`-policy mode that may replace `--dangerously-skip-permissions`.
**Decision**: Until a bounded, user-approved live experiment resolves both questions (warden backlog items), agy dispatch relies on compensating controls: per-model quota caps, artifact-based verify, worktree/branch isolation, post-hoc audit. gemini-3.5-flash (High) is quota-exhausted until ~2026-07-06 regardless.
**Rationale**: Honest floor over pretended interception (charter invariant 8).

## [2026-07-01] Conductor adopts a tiered qualitative-review stage (Conductor reconciliation)

**Context**: `~/AGENTS.md` mandates "review only by an equal-or-higher tier," but Conductor's v1 verify pipeline is mechanical only (new-commit + verify_cmd + optional orchestra). Cycle 1 proved the gap: the Lead session manually re-verified every worker and caught things no verify_cmd would — the committed `.gitignore` landmine, the agy quota no-op, evidence quality — before closing beads.
**Decision**: Adopt an OPTIONAL, config-gated qualitative-review stage in Conductor's verify pipeline, as a NEW bead (`conductor-review`), not a change to the existing M4 beads. After mechanical verify passes, if the dispatched model's tier is below the item's review-ceiling (junior work → senior reviewer; senior work → lead reviewer), Conductor dispatches a READ-ONLY review to an equal-or-higher-tier model returning a structured verdict (ship | revise + findings). Ship → close; revise → bead stays open, findings as a bd comment. Config `review.enabled` (default true) + `review.min_tier_gap`. Each review is one extra dispatch, counted against budget. Mirrors gauntlet's judge and warden's review beads — the whole guild reviews by tier.
**Alternatives considered**: bake review into m4b's verify pipeline (rejected — keeps mechanical vs qualitative verification separable and independently testable); rely on the human at the harness-deck gate for all review (rejected — doesn't scale past propose-only, and the gate reviews the PLAN not the DIFF).
**Rationale**: The guild's review invariant needs a mechanism inside the master-of-works, not just in policy prose. The Lead-by-hand pattern of cycle 1 is exactly what this crystallizes — the same relationship foreman has to Lead-authored specs.

## [2026-07-01] Bursar feeds Conductor's budget (cross-member interface)

**Context**: Conductor's budgets are static caps in conductor.toml today. Bursar's `bursar/status@1` JSON contract reports per-provider window state (or an honest "unknown").
**Decision**: Add a NEW Conductor bead (`conductor-bursar`) to consume `bursar status --json` before dispatching to a metered external backend (pi/agy). Near-exhausted or "unknown" provider windows down-weight or defer external dispatch (fail-closed: "unknown" is treated as spend-cautiously, still counted, never as "plenty"). Blocked on Conductor m4c (dispatch exists) + Bursar shipping its status command; cross-repo dependency noted in bead prose (bd has no cross-repo dep primitive).
**Rationale**: Retires the static-cap limitation and gives orchestra's dormant `ThrottleState`/`routeBoundary` its first real data source through Bursar — one member's output becoming another's input over a file/CLI contract, per the substrate principle.
