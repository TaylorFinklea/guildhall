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

## [2026-07-02] Warden live-enforcement covers Claude Code only; pi/agy = compensating controls (Fable gap review)

**Context**: Warden v1 = policy library + one Claude Code PreToolUse adapter. But the fleet dispatches most work via pi (glm/minimax/qwen) and agy, which run their own inner tool loops. The agy-interception recon proved external live interception of those loops isn't available.
**Decision**: Accept that Warden's LIVE enforcement covers the Claude Code surface only in v1. The pi/agy dispatch surfaces rely on **compensating controls**: worktree/branch isolation, verify-by-artifact, post-hoc `orchestra audit`, quota caps, and prompt-level rules baked into worker prompts. This is exactly the posture this session's dispatch used and it held (zero bad commits across ~23 dispatches). `warden-m6-dispatch-surface-coverage` documents the full matrix + sketches an optional pi-dispatch-wrapper (pre-screen + post-audit, since inner calls can't be gated).
**Alternatives considered**: block pi/agy until live gating exists (rejected — kills the cheap fleet; live gating is proven-unavailable, not merely unbuilt); pretend the Claude adapter covers everything (rejected — charter invariant 8, no papering over gaps).
**Rationale**: Honest floor over pretended coverage. The compensating controls are real and were validated in production this session.

## [2026-07-02] conductor-review gates Conductor v1 (user decision — supersedes "optional")

**Context**: The 2026-07-01 reconciliation ADR added `conductor-review` (tiered qualitative review after mechanical verify) as an OPTIONAL, config-gated stage, and the integration spec's v1-done clause covered only steps 1–2 + member milestones. Asked directly during the 2026-07-02 handoff-hardening session, the user chose to gate v1 on it.
**Decision**: Conductor v1 is NOT done until `conductor-review` ships and gates closes. Bead bumped P2→P1 (still bd-blocked on m4b/m4c); integration spec v1-done clause amended same day. The `review.enabled` config gate remains — what's superseded is only the "optional for v1" framing.
**Rationale**: Cycle 1's Lead-by-hand reviews caught what no verify_cmd could (the .gitignore landmine, the agy no-op, evidence quality). The user wants that mechanized before calling the orchestrator production-ready — mechanical verify alone was the exposed autonomy gap.

## [2026-07-02] Ingestion source coverage: harness-deck + beads are completeness, below recap priority

**Context**: The ingestion-event-model lists 8 sources; Hindsight's recap milestones only budgeted claude-code/codex/pi/agy/guardian. `harness_deck.rs` and `beads.rs` were stubs with no bead.
**Decision**: Add them as `hindsight-m5-hd-beads-sources` at p3 — they complete source coverage but are SUMMARY/AUDIT sources (curated reports; field-change logs), strictly lower value than the primary-transcript recap (m3). Recap ships first with 5 sources; these two round it out.
**Rationale**: A gap worth tracking, not worth blocking recap on.

## [2026-07-03] Month focus: the autonomy ladder leads (user decision, Fable handoff)

**Context**: v1 is nearly closed (conductor-review in flight; conductor-bursar + member final milestones remain). Four thrusts competed for the next month: autonomy (conductor m5/m6/bursar), measurement (gauntlet/provenance/hindsight-why), enforcement depth (warden wrapper + agy experiments), breadth (foreman + envoy transport).
**Decision**: Autonomy ladder leads. Phase A closes v1 (~week 1), Phase B ships ratchet (m6) → triage-suggest (m5) → shadow protocol → conductor-driven cutover. Measurement/enforcement/breadth are explicitly out of scope for the month (warden pi-wrapper captured as P3 backlog; foreman stays deferred).
**Rationale**: Conductor running the guild's own backlog is the product's core promise; everything else plugs into it. Full plan: `phases/2026-07-autonomy-month-spec.md`.

## [2026-07-03] Autonomy posture: earned junior/S auto-dispatch (config default), spec ceiling unchanged

**Context**: m6's pinned ratchet policy (spec § Ratchet) supports auto-dispatch up to {senior,junior}-floor and ≤M complexity after 3 clean cycles. Asked directly, the user chose a narrower month-1 posture.
**Decision**: The ratchet MECHANISM ships per the pinned spec (ceiling {senior,junior}/≤M, invariant 9 relock, lead never auto). The month-1 CONFIG DEFAULT is junior-floor + S-complexity only. Widening toward the spec ceiling is a human config change justified by ratchet evidence — never a silent default bump.
**Rationale**: Mechanism/policy split — build the general machine once, let trust widen the policy. Matches "mis-triaging down is the expensive error": start narrow.

## [2026-07-03] Cutover to conductor-driven dispatch: shadow-first, evidence-gated

**Context**: The whole point of Conductor is to replace hand-orchestration; the question was when to switch.
**Decision**: Shadow protocol — every Opus session runs `conductor cycle --dry-run` alongside hand-orchestration and diffs conductor's plan vs actual routing (recorded on bead `conductor-shadow-cutover`). Cutover after 3 consecutive matching sessions (divergences count as matches only if Opus judges conductor's routing equal-or-better). Post-cutover, `conductor dispatch` (approval-gated) becomes the default loop.
**Alternatives considered**: immediate cutover at v1 (rejected — rough edges would hit real work with no baseline); hand-orchestrate all month (rejected — product ships unproven).
**Rationale**: Evidence-based cutover produces a mismatch trail that is itself the bug backlog.

## [2026-07-03] Claude-spend policy for the month: strict reserve + structurally-Claude carve-out

**Context**: Opus becomes the month's orchestrator while the user's Claude limits are constrained; the external fleet has hard quota rhythms (gpt-5.5 ~3 heavy items/5h; opencode-go weekly; agy per-model).
**Decision**: Claude is spent ONLY on: orchestration + verify-by-artifact (Opus), lead-floor beads (Sonnet), adversarial review of L-items, and **structurally-Claude beads** — work that by nature requires a Claude harness (skill dogfoods, e.g. envoy-e2e-dryrun). Fleet-eligible senior work WAITS for fleet resets (poller pattern). No P1 exception; if the whole fleet is down, work the human tails, docs, or stop.
**Rationale**: The user chose the strictest option explicitly. The fleet's quota rhythms are known and short; waiting is cheap, Claude isn't.

## [2026-07-07] The ready queue must encode the plan (queue hygiene as cutover precondition)

**Context**: Shadow session 1 (bead `conductor-ilv`) diffed Conductor's dry-run plan against Fable's actual routing. A whole mismatch class came from Conductor proposing beads the month plan excludes (Phase B items, do-not-list captures, human tails) — Conductor routes the entire ready queue and cannot know prose plans.
**Decision**: Out-of-phase work is encoded INTO the queue, not held in orchestrator memory: defer with a date (`bd defer --until`) for time-based scope (conductor-m5 → 07-10, warden-44n → 08-01, roster-router P1 beads → 07-10), dependency-block for ordering (conductor-m6 blocked-by conductor-24e + conductor-h23), and leave human-tail beads ready (they are nagged, not hidden). Shadow-diff verdicts only count routing mismatches on beads both sides agree are in play.
**Rationale**: Makes the shadow comparison honest (measures routing quality, not plan awareness), and is a hard precondition for cutover — a post-cutover Conductor dispatching from an un-hygienic queue would faithfully execute the wrong plan.

## [2026-07-07] Secrets-sensitive routing: credential-adjacent content never goes to free/trains-input lanes

**Context**: hindsight-m4 (fixture secrets-audit, junior/S) was proposed by Conductor for the free `glm-5.1` lane — per-algorithm correct (lowest qualifying tier, cheapest lane). But the task's *content* is potentially credential-bearing, and free lanes may be trains-input.
**Decision**: Tasks whose content is secrets-adjacent (audits of possibly-credential-bearing data, key-handling code, tokens in fixtures) route only to paid lanes regardless of tier_floor/complexity. This is a content-sensitivity axis orthogonal to capability; until the roster-router spec's `provider_risk`/`data_policy` metadata can express it (Phase 1+), it is an orchestrator judgment rule.
**Rationale**: The cost delta is pennies; the downside (secrets in a training corpus) is unbounded. Mirrors the existing `data_policy: trains-ok` fail-closed posture.

## [2026-07-09] OpenWiki pilot in Guildhall as reference docs only

**Context**: User asked whether OpenWiki should move beyond the conductor pilot and then requested a Guildhall pilot, because Guildhall is the session-init shell for Conductor/Guildhall orchestration.
**Decision**: Keep the generated `openwiki/` docs in Guildhall as a reviewed pilot, but only as codebase-reference/orientation material. `~/AGENTS.md`, `.docs/ai/current-state.md`, `.docs/ai/decisions.md`, `.docs/ai/phases/*`, and beads remain authoritative for rules, live state, decisions, specs, and backlog. The generated `AGENTS.md` pointer was manually softened so agents do not read OpenWiki before normal session state.
**Rationale**: Guildhall is a low-risk first target: clean repo, thin `AGENTS.md`, no open local beads, and high value as a suite map for sessions that initialize Conductor. The output accurately captured the suite map and operational loop, but it also demonstrated the main risk: generated docs can stale-date live workflow claims, so they must not outrank handoff/ADR/beads state. Do not roll OpenWiki to Tesela or all projects until this pilot is used in real sessions and the docs remain useful without confusing state authority.

## [2026-07-09] GPT-5.6 joins the closed Codex roster with effort-aware roles

**Context**: The local Codex catalog added `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna` with model-specific reasoning options. Conductor previously had no direct Codex backend or per-roster reasoning field, so routing these models through Pi would both fail and lose Sol's `max` level.
**Decision**: Add direct Codex roster rows and pass effort per dispatch: Sol = Fable-equivalent Architect / Lead at `max`; Terra = Opus-equivalent Lead at `xhigh`; Luna = Sonnet-equivalent, with `low`/`medium` Junior and `high`/`xhigh`/`max` Senior. Sol/Terra may also use `ultra`, but it is not their default; Luna rejects it. These are metered external routes and do not satisfy a structurally-Claude harness constraint. GPT-5.5 remains in the roster.
**Rationale**: The roster must encode capability and invocation together so Conductor, Ralph, the then-current comparison tooling, scorecard drift, and the digest agree on the exact model/effort pair. Per-dispatch effort prevents one global Codex config from accidentally changing a worker's tier.

## [2026-07-10] Retire GPT-5.5 from active routing

**Context**: GPT-5.6 Sol, Terra, and Luna are now available with explicit effort-aware roles. Keeping GPT-5.5 as a live roster, alias, comparison profile/judge, and Gauntlet baseline would leave a superseded dispatch path selectable.
**Decision**: Remove GPT-5.5 from the Conductor roster and then-current comparison configuration, the live scorecard and tiers table, Ralph aliases and enabled models, current dispatch guidance, and Gauntlet's allowlist/baseline. Gauntlet uses Qwen-Max as its runnable Pi baseline; Orchestra's OpenAI boundary route uses GPT-5.6 Terra. Preserve GPT-5.5 in historical ledgers, benchmark rows, and report evidence only. This supersedes the 2026-07-09 decision's temporary preservation of GPT-5.5.
**Rationale**: A closed roster must not retain a superseded model as a selectable lane. Historical evidence remains useful for scorecard provenance, but must not become a dispatch affordance.

## [2026-07-13] Charter amendment: stdout JSONL is a permitted live-query layer

**Context**: The [2026-07-01] substrate ADR says members communicate "exclusively through durable files" and that new IPC requires a charter amendment. The suite is now to gain stdin/stdout contracts. Strictly read, that is new IPC.
**Decision**: Amend the substrate principle with one general permission — **stdout JSONL is a permitted live-query surface alongside the disk bus; the disk bus remains the durable record.** These are two LAYERS, not two peers: a stdout view is derived from an artifact, never the reverse, and the artifact always wins. Every stdout envelope carries `artifact{path,sha256}` identifying the record it is a view of. This is a single general permission, not a per-integration mechanism; no further amendment is needed per endpoint.
**Alternatives considered**: leave the charter alone and ship pipes out-of-charter (rejected — the next audit correctly flags it, and the rule erodes by convenience rather than by decision); a broker/daemon (rejected 2026-07-01, still rejected); MCP servers per member (rejected — the fleet's agents are shell-first; see spec § Risks).
**Rationale**: The [2026-07-01] Bursar ADR already blessed "one member's output becoming another's input over a **file/CLI contract**, per the substrate principle" — a CLI contract was sanctioned then and used exactly once. This amendment generalizes what was already adopted. Crucially, the artifact-identity rule **preserves** "exit codes are testimony; artifacts are evidence": a cheap consumer trusts stdout, and a consumer about to spend money re-reads the artifact and verifies the hash. Without that rule, a naive `bursar check && dispatch` would re-introduce the exact agy-exits-0 failure mode the scar was earned from.

## [2026-07-13] The ingestion fix is a pipe, not a shared crate

**Context**: The [2026-07-01] ingestion ADR prohibits parser forks and anticipated the remedy as "extracted to a shared lib in one move." gauntlet then forked the pi-log parser anyway (`src/cost.rs`, 2026-07-09, a week after hindsight's lib shipped).
**Decision**: Satisfy the ADR's *requirement* (one parser, one ground truth) by a different *mechanism* than it anticipated: **hindsight publishes `hindsight events --json`; consumers read the format. No member takes a Rust path-dependency on hindsight.** Provenance's independently-defined view structs are correct decoupling and are explicitly NOT a defect — the earlier audit draft wrongly flagged them. Only gauntlet's forked *parser* is the violation, and it is retired by consuming the stream.
**Alternatives considered**: shared crate (rejected — binds three independently-released repos into one build graph, serves only Rust callers when envoy is bash, and shipping a library coupling to satisfy a Unix-composability mandate is self-defeating; the perf case is void at human cadence); both (rejected — double the surface and double the drift risk for two consumers).
**Rationale**: The ADR's rationale was "two divergent parsers would disagree about ground truth — fatal for an audit tool." A single publishing parser satisfies that as completely as a single linked crate, and serves every caller (Rust, bash, jq, ad-hoc shell) instead of only Rust ones. The format is the contract.

## [2026-07-13] Suite composability admitted as a fourth thrust (amends the month-focus lock)

**Context**: The [2026-07-03] month-focus ADR locked the month to the autonomy ladder and put measurement/enforcement/breadth "explicitly out of scope." A Unix-composability pass across six members is none of those three — it is a fourth thrust, and the ADR did not authorize it.
**Decision**: The user, asked directly on 2026-07-13, authorized all three slices of `phases/unix-composability-spec.md` as a deliberate fourth thrust. The month-focus ADR is amended, not overridden: the autonomy ladder remains the month's lead, and Slice 1 is claimed as Phase-A work regardless, because it repairs a v1 claim that is currently **false** — `conductor-bursar` is marked SHIPPED in the roadmap but is functionally dead in production (bursar is not on PATH, so the budget gate silently degrades to static caps).
**Rationale**: Two of the three slices are cheap (~1 day each) and one of them closes a fail-open money gate that violates charter invariant 3. Deferring Slice 1 to honor a scope lock would mean knowingly leaving a spend guardrail disabled. The autonomy-ladder items (`conductor-xa5`, roster-router chain) slip by the cost of the thrust; the user accepted that trade explicitly.

## [2026-07-14] Suite-wide adversarial review: findings and the root cause

**Context**: With fresh Fable budget, a full architecture+bug review ran across all 8 members: 6 Sonnet discovery agents + a Lead pass, then an 8-run adversarial round (GPT-5.6 Sol ×2, Terra ×3, glm-5.2 ×3) that independently verified every P0/P1 against source — several by binary reproduction. Findings filed as beads in each member's bd (conductor-1i9/9uk/vnu/ldz/z8z/jx2/eua/wxx/z90/1br/cwl; warden, hindsight, provenance, gauntlet, bursar, envoy sets; guildhall-y10/6mc suite-level).
**Decision (recorded, not a choice to relitigate)**: The review's root cause is structural, not a list of unrelated bugs: **every member's pure logic is clean and well-tested (green cargo test, clippy clean), but every integration seam — adapter, pipe, cycle wiring — fails open and is untested.** "Shipped" was repeatedly defined as "unit tests green," which is why unwired/fail-open seams shipped (hindsight M4/M5 parsers never called; warden adapter never wires audit/config; conductor-m6 ratchet never wired to a live cycle; conductor-bursar budget gate a no-op). The two class-level fixes are guildhall-y10 (make the pipe a *verified protocol* with a schema+artifact envelope, not bare JSON) and guildhall-6mc (add a live-seam smoke check to the definition of done).
**Adversarial corrections worth keeping**: (a) warden's crash path is NOT a blanket fail-open — on CC 2.1.209 exit-1+deny-JSON blocks (Sol read the runtime; Terra was misled by the SKILL.md doc); the real residual is the uncaught-panic path. (b) The commit_evidence redaction hole leaks only literal-plaintext `-m`/readable `-F`, not shell-var `$SECRET` (the lexer doesn't expand env). (c) gauntlet's cost_usd coercion is fail-closed for the all-malformed case; only mixed valid+malformed undercounts. (d) provenance's independent view structs are correct decoupling, not a fork. Filing at calibrated (often lower) severity because of these.

## [2026-07-14] Autonomy target for the next few weeks: SUPERVISED autonomy, not unattended

**Context**: The month goal was "autonomy ladder done" — `conductor dispatch` as the default unattended loop. The review found this is not a safe few-weeks target. GPT-5.6 Sol (architecture) surfaced, and direct inspection confirmed, the linchpin (conductor-1i9): conductor's worker-success check is **identity-free** (`dispatch.rs:350-352`/`verify.rs:161-162` treat ANY new HEAD as success, not the worker's own commit) and the dispatch path has **no exclusive repo lease** — so the "clean session" signal the ratchet would use to auto-escalate privilege can be forged by any concurrent commit (the exact failure already logged in current-state.md). Compounding: the ratchet is unwired, the dispatch loop is fail-stop with no resume, and the safety floor (warden) is not installed and its adapter fails open.
**Decision**: The user, asked directly on 2026-07-14, retargeted the near-term goal from **unattended** to **supervised autonomy**: batch-approve a bounded plan → auto-execute with per-item resume → human reviews after. The ratchet stays **observe-only**. Unattended junior/S becomes a narrow later canary, only after warden-enforcement, resilient/resumable execution, exclusive repo ownership, trustworthy verification, and provider fail-closed all have fresh operational evidence.
**Rationale (Sol's verifier-trust bar)**: a mechanism must not escalate its own privilege from a signal the same write-capable system can forge or misclassify — and `ratchet.rs::evaluate` currently gates on "a verify_cmd exists," which is dispatchability, not evidence trustworthiness. Three correlated false PASSes are not stronger than one. Sequencing (Sol, 8 gated steps) is captured in the roadmap.

## [2026-07-14] Warden's near-term role: shadow/logging mode, effectiveness TBD

**Context**: Warden is the designated safety floor but is not installed as a live hook, and its adapter fails open in several ways. Sol argued for making it an enforced blocking dependency (conductor refuses to dispatch without it).
**Decision**: The user chose a softer near-term posture: run warden in **shadow/logging mode** — it classifies each tool call and records the verdict it *would* have issued ("would have denied X"), without blocking — to gather evidence on its effectiveness before trusting it as a gate. Work reprioritizes accordingly: add the shadow/dry-run mode, **wire the audit sink** (`core/src/audit.rs` exists but the adapter never calls it — this is the enabler), and install it log-only via a pending-human handoff. The adapter fail-opens (symlink, renamed-input, obfuscation, headless) drop from P0 blockers to P2 accuracy-of-advice issues, since a shadow logger that misclassifies gives misleading advice but blocks nothing.
**Rationale**: matches the supervised-autonomy posture — observe-and-advise first, enforce once there's evidence the policy is right. Enforcement (Sol's step 2) returns as a gate later.

## [2026-07-14] The audit pipe must be correct; breadth-stabilize leads the first weeks

**Context**: Two more direction calls. The audit pipe (hindsight→provenance/gauntlet) has real correctness defects (empty-message and cross-repo false attribution, three unwired sources, no envelope); the user relies on it daily. And with limited weeks, one thrust must lead.
**Decision**: (1) **The audit pipe must be correct** — false attribution is worse than no attribution, so provenance's join defects (guildhall bead set), hindsight's unwired sources, and the envelope (guildhall-y10) are must-fix, not best-effort. (2) **Breadth-stabilize leads the first 1–2 weeks** — sweep the P1/P2 fixes across all members (exit codes, redaction, test flakes, envoy validator, the audit-pipe correctness items) rather than a single deep conductor thrust. The deep conductor autonomy work (repo lease + identity-checked success + resumable loop, conductor-1i9/vnu/9uk) is filed and tracked as the supervised-autonomy track but is not the immediate lead.
**Rationale**: breadth-first restores trust in the tools the user actually uses daily and clears the long tail of fail-open seams; the audit-pipe correctness items ride inside that sweep at high priority. The autonomy track proceeds in parallel as capacity allows, gated by the [2026-07-14] supervised-autonomy sequencing.

## [2026-07-14] Retire Guildhall as a runtime product; Conductor becomes the explicit job-loop core

**Context**: The eight-member Guildhall design accumulated overlapping state machines and ownership: Ralph already runs the fresh-context phase loop, Conductor scans/routes/dispatches, Conductor and the live scorecard both describe the roster, Gauntlet owns another executor/eval path, Provenance owns a second evidence store, and Envoy/Foreman remain separate packaging for behavior that can be a job or skill. The user challenged whether the abstractions would earn their keep and chose a Linux-style shape: one focused core plus small pipeable tools. The adversarial reviewer has repeatedly earned its keep and must survive. Model and harness scorecards now also need a durable empirical home.

**Decision**: Adopt `phases/conductor-core-consolidation-spec.md`, as amended by the 2026-07-22 role-routing cutover below. **Conductor** owns one explicit, verified, resumable job-loop kernel with a closed first-release job set (`work`, `review`, `consult`, `plan`); the existing N-reviewer plus independent-judge adversarial flow becomes `review`, while `plan` is a separate bounded artifact-producing job. **Bursar** owns strict v2 provider/execution-profile identities, unordered role capabilities, and availability facts; Conductor owns enabled role pools, weights, selection, fallback, and gates. **Hindsight** owns canonical append-only human observations, a rebuildable SQLite evidence index, attribution, and model/harness/profile/job scorecards; it may propose but never apply roster changes. **Warden** becomes a stateless read-only Hindsight-event filter that emits advisory findings. Provenance folds into Hindsight, Gauntlet remains corrected evaluation evidence for Conductor plan/review plus Hindsight scorecards, Envoy folds into `consult`, and Foreman into a skill. Guildhall remains only through migration proof and then is archived. Ralph becomes a temporary compatibility shim only after Conductor reaches loop parity; Conductor does not wrap Ralph as a second permanent state machine.

The Hindsight SQLite database is derived, never sole truth: raw harness artifacts, Git, Conductor run artifacts, and `observations.jsonl` are canonical. Start with SQLite rollback-journal mode, not WAL, because the SQLite WAL-reset corruption bug disclosed in 2026 affects the currently inspected local/bundled versions; WAL requires an explicit fixed-version gate if reconsidered. There is no daemon, broker, workflow DSL, shared Cargo crate, or automatic scorecard-to-roster feedback loop.

**Supersedes**: the [2026-07-03] unattended Conductor cutover/ratchet as a product goal; `conductor-jx2`, `conductor-ilv`, and automatic triage-backfill work. It preserves the identity/lease/resume/fail-continuation fixes (`conductor-1i9`, `vnu`, `9uk`) as loop-kernel prerequisites. It also supersedes the same-day Warden shadow-hook installation path (`warden-4ke`/`wyd`/`gqw`) with a simpler batch read-only Hindsight consumer; Warden enforcement remains out of scope until evidence justifies a separate decision.

**Alternatives considered**: keep eight independently growing products (rejected: most boundaries have not earned separate state/execution); put roster, evidence, policy, and execution into Conductor (rejected: creates the black box the redesign is meant to avoid); keep Ralph as Conductor's permanent inner engine (rejected: two resumable state machines and split truth); make SQLite canonical or add Postgres/DuckDB (rejected: raw evidence must remain inspectable/rebuildable and a local CLI workload does not justify a service); automatically tune Bursar from scorecards (rejected: correlated verifier errors must not escalate model privilege).

**Rationale**: Four questions remain independently useful and testable: Conductor answers how an explicit job completes, Bursar who can run, Hindsight what happened/how profiles performed, and Warden what deserves attention. Everything else becomes data, a job, a skill, or history. Versioned JSONL plus artifact hashes preserves the existing Unix composability ADR while sharply reducing hidden control surfaces.

## [2026-07-17] Roster maintenance UI belongs to Bursar

**Context**: The consolidation spec canceled the old Conductor roster TUI until the read-only Bursar CLI earned operational demand. Bursar now owns the canonical roster and ships `roster list`, `check`, and `snapshot`; the user has explicitly asked to maintain the roster interactively after exercising those surfaces.

**Decision**: Build the optional roster and availability TUI in Bursar (`bursar-vsv`), never Conductor. Roster edits remain staged, validated, diffed, atomically written, and human-confirmed. Manual allow, defer, and clear actions remain append-only availability observations on a visibly separate surface. Hindsight may show evidence and recommendations but cannot apply them, and Conductor continues to own only job selection and fallback policy.

**Supersedes**: only the consolidation spec's no-demand TUI cancellation. It does not change Bursar roster ownership, fail-closed eligibility, or the ban on automatic scorecard-driven roster mutation.

**Rationale**: The read-only CLI established the ownership boundary; the remaining problem is safe human ergonomics, not another source of truth. Keeping the UI in Bursar lets one validator and one roster contract govern both terminal and non-interactive workflows.

## [2026-07-22] Add role-aware planning and cut strict v2 state

**Context**: OMP exposes functional model roles, but Bursar v1 carried no role
capabilities and Conductor reduced an eligible route to one primary plus retry
fallbacks. The comparison job also duplicated execution policy instead of
serving the explicit-target product.

**Decision**: Replace the fourth native job with `plan`; the closed set is
exactly `work|review|consult|plan`. `review` retains its N-reviewer plus
independent-judge contract. `plan` authors a strict spec or implementation plan
under bounded peer review and, for specs, a distinct final second opinion. It
is neither a hidden `work` phase nor another loop engine.

Bursar v2 advertises unordered validated role capabilities and exact
profile/execution/provider identities. Conductor owns generic role bindings,
60/20/20 initial plan weights, deterministic durable smooth weighted
round-robin, retry order, relational reviewer constraints, approvals, and
stopping rules. Strict `conductor/run@2` and `conductor/event@2` live only in
`runs-v2/` and pin a copied exact Bursar snapshot; v1 state is never parsed by
the new binary.

**Supersedes**: the 2026-07-14 fourth-job and v1 run/roster portions, the open
`conductor-arena-loop` and `conductor-eval-fold` backlog paths, and any active
operator contract selecting a comparison runtime. Closed v1 Beads and Git
history remain evidence only. The corrected Gauntlet corpus remains an
evaluation source for plan/review and does not become another runtime.

**Rationale**: Role capability is a roster fact; weighted selection and review
policy are Conductor decisions. Durable deterministic rotation gives auditable
proportional exposure without random streaks, while strict copied snapshots and
structural v2 state preserve immutable approval and resume safety.
