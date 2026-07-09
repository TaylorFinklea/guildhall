# Guildhall v1 finish + product demo — Implementation Plan

> **For agentic workers:** execute task-by-task; each task ends with an independently verifiable deliverable. Steps use `- [ ]` for tracking. This plan is orchestration-heavy: Phase A is git-ops, Phase B is worker-dispatch + verify, Phase C is an integration build. The gauntlet m5/m6 workers do their own TDD per their beads.

**Goal:** Finish the bounded remaining Guildhall v1 work, adopt OpenWiki, and ship a runnable per-member demo harness in `guildhall/demo/`.

**Architecture:** Three sequential sub-projects (A adopt-OpenWiki → B finish-v1 → C demo). B dispatches gauntlet m5/m6 to minimax-m3 and orchestrator-verifies; C is built by the orchestrator (holds cross-member context).

**Tech Stack:** Rust members (cargo), shell demo runner, beads (bd), pi dispatch (ollama-cloud/minimax-m3), harness-deck.

## Global Constraints (verbatim from spec)

- Foreman: honored-deferred — NO build; honest "spec-only, deferred to 2026-08 per ADR" demo panel.
- Out of scope (never touch): Phase-B (roster-router, conductor-m5, cutover/xa5), warden/envoy/hindsight v1.5, Envoy live transport.
- `demo/run.sh all` default run must perform **NO metered dispatch**.
- tiers.md patch (gauntlet-m6 output) is a **pending-human handoff** — never applied by the fleet.
- guildhall commits stay **surgical** (explicit paths) — the user has concurrent uncommitted work here.
- Every verify judges by artifact, never exit code alone. Fail closed.

---

## Phase A — Adopt OpenWiki (mechanical)

### Task A1: Keychain-safety + accuracy review
**Files:** review `openwiki/{quickstart,architecture,workflows,operations}.md` (read-only).
- [ ] Run the `conductor-1qh` safety gate:
  `cd ~/git/guildhall && test -d openwiki && ! test -s "$HOME/.openwiki/.env" && ! git grep --no-index -qIE "(sk-[A-Za-z0-9]{20,}|_API_KEY=)" -- openwiki && echo SAFE`
  Expected: `SAFE`.
- [ ] Skim the 4 generated docs against README/current-state for any materially wrong live-workflow claim; fix only clear errors (light touch — they are orientation, not source-of-truth).

### Task A2: Commit adoption + reconcile the pilot bead
**Files:** commit `openwiki/`, `AGENTS.md`, `.docs/ai/decisions.md` (the user's drafted ADR).
- [ ] `cd ~/git/guildhall && git add openwiki AGENTS.md .docs/ai/decisions.md && git commit openwiki AGENTS.md .docs/ai/decisions.md -m "openwiki: adopt generated reference docs for guildhall (orientation-only)"` (+ Co-Authored-By).
- [ ] Confirm nothing else swept in: `git status --porcelain` shows only files unrelated to this change untouched.
- [ ] Reconcile `conductor-1qh` (scoped to harness-conductor; ran on guildhall instead): `bd -C ~/git/harness-conductor close conductor-1qh --reason "OpenWiki piloted+adopted on guildhall instead (decisions.md 2026-07-09, orientation-only). Member-repo runs are an optional follow-on."`
- **Verify:** `git -C ~/git/guildhall log --oneline -1` shows the adopt commit; `git -C ~/git/guildhall grep -q "OpenWiki" .docs/ai/decisions.md`; `bd -C ~/git/harness-conductor show conductor-1qh` = closed.

---

## Phase B — Finish v1 (dispatch + verify)

### Task B1: Dispatch + verify + close gauntlet-m5
**Files:** worker edits ~/git/gauntlet (ab.rs + deck.rs per bead).
- [ ] Write a handoff prompt (mirror the 2026-07-08 dispatch prompts: bead-is-spec, one-shot/unattended, verify `cargo test` + `cargo clippy --all-targets -- -D warnings`, exactly one commit `gauntlet-m5: `, don't push, don't close, `FAILED:` on failure). Read `bd -C ~/git/gauntlet show gauntlet-m5-ab-report` first.
- [ ] Confirm gauntlet is clean + green at HEAD; dispatch via `pi --model ollama-cloud/minimax-m3 --approve -p "$(cat <prompt>)" < /dev/null` in ~/git/gauntlet, backgrounded to a log.
- [ ] On completion: read the log; **independently** re-run `cargo test` + `cargo clippy --all-targets -- -D warnings` in ~/git/gauntlet; review the diff for scope + correctness.
- [ ] `bd -C ~/git/gauntlet close gauntlet-m5-ab-report --reason "<evidence>"`.
- **Verify:** one commit `gauntlet-m5:` on gauntlet main; `cargo test` green; bead closed.

### Task B2: Dispatch + verify + close gauntlet-m6 (after B1)
**Files:** worker edits ~/git/gauntlet; produces a **proposed** tiers.md patch (a file/artifact, not applied).
- [ ] After m5 closes and m6 unblocks, repeat the B1 pattern for `gauntlet-m6-efficiency-workload` (read its bead first). The tiers.md patch is written as a proposed artifact + noted as a pending-human handoff — the worker must NOT apply it to `~/.claude/templates/tiers.md`.
- [ ] Independently verify + review + close.
- **Verify:** one commit `gauntlet-m6:` ; `cargo test` green; bead closed; a proposed tiers.md patch artifact exists in-repo (not applied to ~/.claude).

---

## Phase C — Demo harness (`guildhall/demo/`, built by orchestrator)

### Task C1: Scaffold + build the 3 CLIs
**Files:** create `demo/run.sh`, `demo/README.md`; build hindsight/provenance/bursar.
- [ ] `mkdir -p ~/git/guildhall/demo`. Write `demo/run.sh` skeleton: a dispatcher `run.sh <member>|all`, a helper that prints a labeled `── <Member> [maturity] ──` header per step, and a `--build` path that runs `cargo build --release` in hindsight/provenance/bursar if their binaries are missing.
- [ ] Build: `for r in hindsight provenance bursar; do cargo build --release --manifest-path ~/git/$r/Cargo.toml; done`.
- **Verify:** `bash demo/run.sh` (no args) prints usage; `ls ~/git/{hindsight,provenance,bursar}/target/release/{hindsight,provenance,bursar}` all exist.

### Task C2: Runnable-now members — Conductor, Bursar, Gauntlet
**Files:** `demo/run.sh` (add 3 steps), `demo/README.md` (narrate).
- [ ] Conductor step (`live`, centerpiece = integration proof): `conductor cycle --dry-run --config ~/git/harness-conductor/conductor.toml`, then surface the report path + a metrics summary. This IS `conductor-guildhall-dogfood`.
- [ ] Bursar step (`live`): `~/git/bursar/target/release/bursar status --json` (confirm exact flag via `bursar --help`), pretty-print the provider-window ledger.
- [ ] Gauntlet step (`live`, NO fresh metered dispatch): `~/git/gauntlet/target/release/gauntlet lint golden-tasks` + echo the most recent recorded run (tail `~/git/gauntlet/ai-scratch/e2e-run8.log` or a ledger row) as the evidence example.
- **Verify:** `bash demo/run.sh conductor`, `... bursar`, `... gauntlet` each print a labeled section with real output; no dispatch fired.

### Task C3: Buildable members — Hindsight, Provenance
**Files:** `demo/run.sh` (+2 steps), `demo/README.md`.
- [ ] Discover each CLI from `~/git/hindsight/.docs/ai/phases/*spec*` + `hindsight --help` and `provenance --help`. Hindsight step (`live`): a `recap`-style read over the real transcript substrate (read-only). Provenance step (`live`): an `annotate`-style authorship/exposure audit on a small real repo (read-only), consuming Hindsight ingestion.
- [ ] Each step prints observable output + a one-line "what to look for."
- **Verify:** `bash demo/run.sh hindsight` and `... provenance` print real reports; no writes to real repos.

### Task C4: Special-shape members — Warden (lib), Envoy (script)
**Files:** `demo/run.sh` (+2 steps), optionally `demo/warden_driver/` tiny crate OR use `cargo test`.
- [ ] Warden step (`lib-via-tests`): decide from `~/git/warden/src/lib.rs` public API — either a tiny driver that prints one allow + one gate decision, or run its policy-decision tests with `--nocapture` and surface the gate outcomes.
- [ ] Envoy step (`dry-run`): `bash ~/git/envoy/scripts/validate-envelope.sh` on `fixtures/golden-question.json` → `golden-answer.json` (confirm script args); show the consult envelope round-trip + the `broken-answer.json` rejection.
- **Verify:** `bash demo/run.sh warden` shows a gate decision; `... envoy` shows a valid + a rejected envelope.

### Task C5: Foreman honest panel
**Files:** `demo/run.sh` (+1 step), `demo/README.md`.
- [ ] Foreman step (`spec-only`): print "deferred to 2026-08 per ADR", then show its v1 spec title + the seeded bead DAG via `bd -C ~/git/foreman list` (its blocked/deferred beads). No fake run.
- **Verify:** `bash demo/run.sh foreman` prints the deferred panel + the real seeded backlog.

### Task C6: Capstone — `all` + README + optional deck report
**Files:** `demo/run.sh` (finalize `all`), `demo/README.md` (full narration), commit.
- [ ] Finalize `run.sh all` to run all 8 in vertical-slice order (Conductor → Bursar → Warden → Hindsight → Provenance → Gauntlet → Envoy → Foreman) with maturity labels.
- [ ] Write `demo/README.md`: intro (the guild + substrate principle), per-member section (what/command/what-to-look-for/maturity), and "run it yourself" instructions.
- [ ] (Optional) publish a harness-deck report aggregating the run outputs (dogfoods the substrate principle).
- [ ] Commit `demo/` surgically to guildhall.
- **Verify:** `bash demo/run.sh all` exits 0, prints 8 labeled sections, is idempotent on re-run; `demo/README.md` lets a human reproduce each; `git -C ~/git/guildhall log --oneline -1` shows the demo commit.

---

## Self-review notes
- Spec coverage: A (A1/A2), B (B1/B2 + dogfood folded into C2), C (C1–C6 = 8 members + capstone). All spec sections mapped.
- Foreman non-goal honored (C5 = honest panel, no build).
- No-metered-dispatch-in-demo honored (C2 gauntlet uses lint + recorded run).
- Codebase-derived commands (hindsight/provenance/bursar flags, warden driver, envoy script args) are discovered at execution time per the spec — flagged in C2–C4, not hardcoded.
