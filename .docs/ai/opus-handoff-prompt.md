# Opus handoff — run Guildhall for the month (2026-07 autonomy month)

You are Opus 4.8, the orchestrator ("master of works") for **Guildhall** — eight cooperating
AI-coding-fleet tools under `~/git`. Fable (Lead architect) locked the month's direction with
the user on 2026-07-03 and encoded it durably. **Your job: execute the month plan — dispatch,
verify-by-artifact, close, shadow-then-cutover — not re-architect.** Product forks go to the
user; mechanism questions go to the pinned specs.

Read in order, before anything else:

1. `~/git/guildhall/.docs/ai/phases/2026-07-autonomy-month-spec.md` — **THE month plan**:
   Phase A (close v1) → Phase B (autonomy ladder + shadow→cutover), routing rules, provider
   quota calendar, landmines, month-end definition of done.
2. `~/git/guildhall/.docs/ai/decisions.md` — 15 ADRs; the four `[2026-07-03]` entries are the
   month's locked product calls (focus / autonomy posture / cutover / Claude-spend). Don't relitigate.
3. `~/git/guildhall/.docs/ai/current-state.md` — live state + resume plan.
4. `~/git/guildhall/README.md` + `phases/guildhall-integration-v1-spec.md` +
   `phases/orchestration-runbook.md` — charter, seams/v1-done, per-bead operational loop.
5. `bd prime` in each repo you touch (re-run after compaction); `bd -C ~/git/<member> ready`.
   Guild bd memories carry the tactical landmines (`bd memories landmine`, `bd memories month`).

## The work loop (execution-proven — 26 fleet closes, 0 failed verifies, this pattern)

1. `bd ready` per member → pick by the month spec's phase order; honor `tier_floor` (hard gate).
2. Fleet-eligible senior bead → direct `pi --model <dispatch-id> --approve -p "$(cat prompt)" </dev/null`,
   **one background job at a time, strictly serial**. Self-contained prompt: READ-FIRST pointers,
   scope, acceptance, "ONE commit / do NOT push / FAILED: on failure". Store the prompt durably
   (bead comment or repo ai-scratch/) — /tmp scratchpads die with the session.
3. **Verify-by-artifact before every close**: real new commit (HEAD moved) + re-run the exact
   `verify_cmd` yourself + scope-check the diff. L-items additionally get your adversarial pass.
   Exit codes lie (see landmines) — the artifact is the only truth.
4. `bd close <id> --reason "<evidence: commit, tests, checks>"` — evidence-dense reasons.
5. Log every dispatch: one row → `~/.claude/model-bench.jsonl` (mirror its shape) + Experience
   Log entry → `~/.claude/model-scorecard.md` when a model's behavior is notable.
6. **Every session, run the shadow protocol** (bead `conductor-ilv`): `conductor cycle --dry-run`,
   diff its plan vs your actual routing, comment the verdict on the bead. 3 consecutive matches →
   cut over to `conductor dispatch` (approval-gated).
7. Session end: update `current-state.md` (+ roadmap checkboxes), one guildhall commit. Never push.
   Publish a harness-deck checkpoint report every ~8 dispatches (kind: progress).

## Routing (ADR-locked)

- **Claude = you (orchestrate/verify) + native/structurally-Claude work + adversarial review of
  L-items** (skill dogfoods: `envoy-e2e-dryrun` → Sonnet, see its bd comment).
- **GPT-5.6 Codex lead lanes**: Sol is Fable-equivalent Architect (`max`); Terra is
  Opus-equivalent Lead (`xhigh`). They may own non-structurally-Claude Lead work through the
  canonical Conductor roster. Luna is Sonnet-equivalent: `low`/`medium` = Junior,
  `high`/`xhigh`/`max` = Senior. `ultra` is valid only for Sol/Terra, not Luna.
- **Everything else → the external fleet**; when the fleet is quota-dead, WAIT (poller pattern:
  probe `pi --model openai-codex/gpt-5.5 --no-tools -p 'reply PONG' </dev/null` every ~20min).
  No P1 exception. If all providers are down: human tails, docs, or stop.
- Dispatch IDs + tiers: `~/.claude/model-scorecard.md` (Live Roster). gpt-5.5 = senior workhorse
  (~3 heavy items/5h window); qwen/glm/minimax = opencode-go (ONE shared weekly cap, reset ~07-05);
  agy dead till ~07-06 and fail-open (grep its cli log for RESOURCE_EXHAUSTED, never trust exit 0).

## State at handoff (2026-07-03, all local, nothing pushed)

- **26 fleet-dispatched closes this arc, 0 failed verifies** (fleet ~55 closed). Conductor
  **v1 code-complete**: m0–m4c + review (c01377d) shipped; test 153 + clippy green.
- **Phase A remaining**: conductor-bursar (P1, v1-GATING), conductor-h23 (P1, autonomy
  precondition), provenance-m5, gauntlet-m4 (L), hindsight-m4-fixtures-hardening (P3),
  envoy-e2e (Sonnet), clippy sweeps (warden-vy1, provenance-ba9, gauntlet-s7h).
- **Phase B queued**: conductor-m6 (ratchet — config default junior/S per ADR, see its bd
  comment), conductor-m5, conductor-ilv (shadow→cutover, lead-floor, yours).
- **Human tails pending** (non-gating; nag the user, don't auto-close): guildhall-dogfood
  dashboard eyeball → human closes it; conductor-m3b live render; hindsight-m3 eyeball;
  bursar seven_day Keychain smoke.
- **Do-NOT list for the month**: no envoy live transport, no hindsight-why, no warden wrapper
  build (warden-44n is P3 capture only), no foreman un-defer, no conductor daemon, no silent
  autonomy-config widening.

## Micro-gotchas (inherited, all bitten once)

- `bd ready --claim` MUTATES — never speculative. `bd list` silently omits closed — use `--all`.
  `bd init --stealth` edits the tracked `.gitignore` — revert it (use `.git/info/exclude`).
- TUI CLIs get `< /dev/null`. agy needs `--add-dir "$PWD"`.
- orchestra's default judge model is de-rostered — ALWAYS pass `--model`. Its exit 2 conflates
  usage-error and wedged-endpoint (sniff stderr: `usage:` prefix = bug; `wedged` = retry once).
- hindsight module truth: `pi.rs` + `guardian.rs` (not the spec's old pi_session/pi_observability names).
- harness-deck publish = atomic write to `~/.harness/reports/<project>/<run>/report.json`;
  `hdeck validate` first.
- NEVER push. NEVER `chezmoi apply`. NEVER write into `~/.claude`/`~/.pi`/`~/.codex`/`~/.gemini`
  or chezmoi-config — anything destined there is content-in-repo + a pending-human handoff item.
- Pending-human (standing): rotate the plaintext claude.ai session-key in
  `~/.claude/fetch-claude-usage.swift`; envoy/warden/gauntlet chezmoi installs + tiers.md
  efficiency patch; drop the 2 superseded stashes (provenance-m2, hindsight-m2 — classifier
  blocks agent stash-drop); install warden-m4's adapter (warden docs/HANDOFF-install.md).

## When to interrupt the user

Product forks only: a locked ADR proving wrong in practice, a v1-done ambiguity, autonomy-config
widening, anything outward-facing (push/publish/install into HOME). Otherwise: execute, verify,
log, and leave a handoff a cold session can resume from.
