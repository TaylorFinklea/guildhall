# Opus handoff — take over Guildhall execution

You are Opus 4.8, the orchestrator ("master of works") for **Guildhall**, a suite of
eight cooperating AI-coding-fleet tools under `~/git`. Fable (the architect) has done
the decomposition AND a full 9-repo handoff audit (2026-07-02): specs and beads exist
for every member, every open bead carries `tier_floor`/`complexity`/`verify_cmd` in bd
metadata, sequencing gates are encoded in bd, and the docs below are current. **Your
job is to execute the backlog — dispatch each bead to the lowest capable model, verify
by artifact, close it — not to re-architect.** Read before doing anything else, in order:

1. `~/git/guildhall/README.md` — the charter (metaphor→function map, 9 suite invariants, the substrate principle).
2. `~/git/guildhall/.docs/ai/phases/guildhall-integration-v1-spec.md` — how the members compose, the cross-repo dependency graph (bd has no cross-repo deps — honor it manually), and what "v1 done" means (now includes `conductor-review` — user decision 2026-07-02).
3. `~/git/guildhall/.docs/ai/phases/orchestration-runbook.md` — **the operational doc**: the per-bead loop, budget caps (user-approved), human-verify-tail list, provider-limit handling, crash recovery. Execution-proven; follow it.
4. `~/git/guildhall/.docs/ai/current-state.md` — live state, stashes, resume plan.
5. `~/git/guildhall/.docs/ai/decisions.md` — 11 ADRs. Don't relitigate.
6. `bd prime` in any member repo; then `bd -C ~/git/<member> ready`.

## What's already done (verified — don't redo)

~22 beads dispatched, verified-by-artifact, and closed: **Conductor cycle 1 complete
(8/8 + an Opus adversarial review that caught a real untested safety guard)**; envoy
(all but its e2e test); warden m0/m1/m2 (the classify+policy+state policy core);
hindsight m0/m1/m2-codex; bursar m0; provenance m0/m1. All local, nothing pushed.
Builds green at HEAD: conductor 84 tests, warden 39, hindsight 59, bursar 4.

## Immediate work queue (gates are now IN bd — trust `bd ready`, plus the notes below)

- **`warden-rev` first** (LEAD — you or another Claude lead, NEVER a senior/pi model;
  the author was Fable, use a different lead). warden-m3 is bd-blocked on it.
  Mutation-check the invariants like Conductor's rev1 did.
- **Redo (stashes available)**: `hindsight-m2-pi-parser` — **landmine**: the stash's
  `pi_session.rs` is an orphan under the committed module layout; FOLD it into
  `src/sources/pi.rs` (bead comment + hindsight decisions.md ADR have details).
  `provenance-m2` — pop and build on it.
- **Wide-open parallel lanes** (one writer per repo): bursar-m1/m2/m3;
  envoy-e2e-dryrun; provenance-seam (LEAD) + provenance-m2; conductor
  m4a/m3a/m1c/m0c/agy/cov1; gauntlet-m0.
- **Deferred — do NOT dispatch**: all six foreman beads (built LAST; un-defer when the
  other six members ship v1) and `conductor-warden` (v1.5).
- **`conductor-review` is P1 and GATES v1** (user decision 2026-07-02) — it unblocks
  after m4b/m4c; don't let it slip to "optional".
- **Then**: finish each member to its spec's final milestone in build order
  (`warden → hindsight → envoy → bursar → provenance → gauntlet → foreman`);
  Conductor M3/M4 chains in parallel.

## Dispatch discipline (non-negotiable — this held for ~22 clean dispatches)

- **Route by tier**: read each bead's `tier_floor`/`complexity` from bd metadata BEFORE
  claiming. `tier_floor: lead` → Claude lead only, never a senior pi model — a
  below-floor dispatch is a bug. Senior/junior → cheapest capable: pi
  (`opencode-go/{glm-5.2,minimax-m3,qwen3.7-max}`, `openai-codex/gpt-5.5`) or a Sonnet
  subagent.
- **One writer per repo.** Claim (`bd -C <repo> --actor <model> update <id> --claim`)
  before dispatch; release (`--status open --assignee ""`) with a comment if a worker dies.
- **Verify by artifact, always.** After a worker finishes, YOU re-run the bead's
  `verify_cmd` AND confirm a new commit exists — never trust the worker's word or its
  exit code (agy exits 0 on quota no-ops). **Seven beads have human-verify tails**
  (runbook § Human-verify tails) — verify_cmd green is NOT acceptance for those; do the
  tail or flag it. Only then `bd close <id> --reason "…"`.
- **Budget caps (user-approved 2026-07-02, "Moderate")**: ≤10 bead closes/session,
  ≤3 concurrent Anthropic subagents, pi until first 429 → release + hold (never retry
  into a limit), harness-deck checkpoint every ~8 dispatches.
- **Log every non-default dispatch** to `~/.claude/model-bench.jsonl` (mirror the row
  shape) + a one-line Experience Log entry in `~/.claude/model-scorecard.md`.
- **Worker prompts**: wrap task data in delimiters as untrusted; rules AFTER the data;
  forbid push/bd/chezmoi/out-of-repo writes; require ONE commit + self-run verify.
  Mirror `~/git/harness-conductor/templates/worker-prompt.md`.
- **Give lead-tier cores an independent adversarial review** (a different lead than the
  author) — it caught real bugs twice.

## Backend reality

**Check limits LIVE before dispatching — every printed reset time in these docs is
stale by the time you read it.** Standing facts: agy (gemini-flash) quota-dead until
~2026-07-06 — parked; junior work falls to lean seniors (minimax). opencode-go
(glm/minimax/qwen) and gpt-5.5 have recurring 5h/usage windows — a `429` in worker
output means release + hold, don't retry. When cheap backends are all throttled, HOLD
rather than overload Anthropic (that tripped the session limit mid-session once and
truncated a doc mid-write).

## Landmines (hard-won — all execution-proven)

- `bd ready --claim` MUTATES — never speculative. TUI CLIs get `< /dev/null`. agy needs
  `--add-dir "$PWD"`.
- `bd init --stealth` edits the tracked `.gitignore` — revert it (mechanism is
  `.git/info/exclude`). `bd list` silently omits closed beads — use `--all`.
- The hindsight stash orphan-file trap (above). Module truth: `pi.rs` + `guardian.rs`,
  not the spec's old `pi_session.rs`/`pi_observability.rs`.
- orchestra's default judge model is de-rostered kimi — always pass `--model`. Its
  exit 2 conflates usage-error and wedged-endpoint (sniff stderr).
- harness-deck publish is atomic file-write to `~/.harness/reports/<project>/<run>/report.json`;
  validate with `hdeck validate` first.
- NEVER push. NEVER `chezmoi apply`. NEVER write into `~/.claude`/`~/.pi`/`~/.codex`/
  `~/.gemini` or chezmoi-config — anything destined there is content-in-repo + a
  pending-human handoff item.
- Pending-human: rotate the plaintext claude.ai session-key in
  `~/.claude/fetch-claude-usage.swift`; envoy/warden/gauntlet chezmoi installs + the
  tiers.md efficiency patch.

Publish a cycle/checkpoint report to harness-deck every ~8 dispatches (kind: progress).
Ultracode is on — be exhaustive; use adversarial reviews and honest gap-reporting.
