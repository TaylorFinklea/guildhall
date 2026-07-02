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
