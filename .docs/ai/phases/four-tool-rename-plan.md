# Four-Tool Clean Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename Conductor→Undertake, Bursar→Musterroll, Hindsight→Afterfact, and Warden→Cautionlight as one clean, dependency-ordered local and remote suite transaction.

**Architecture:** Prepare and verify all source cutovers before mutating remotes or HOME. Preserve immutable historical artifacts through a path-level allowlist, migrate only live operational state into new namespaces, then rename remotes/checkouts and publish managed configuration in dependency order. No compatibility aliases or dual readers survive.

**Tech Stack:** Rust 2024/1.85, Cargo, SQLite/rusqlite, Bash 3.2, Git/GitHub CLI, chezmoi composition, harness-deck, Beads, Node.js scorecard tooling.

## Global Constraints

- Exact mappings: `conductor→undertake`, `bursar→musterroll`, `hindsight→afterfact`, `warden→cautionlight`.
- Clean break: no old CLI wrappers, schema aliases, config fallback, or dual state-root reads.
- Preserve Git history, dated completed records, archived run payloads, and historical source labels.
- Current operational source, tests, docs, schemas, paths, packages, remotes, checkouts, installations, and HOME use only new names.
- Keep neutral names such as Musterroll’s `roster.toml` and Afterfact’s SQL table names unless they encode a product identity.
- Zero in-flight jobs before remote, checkout, state, install, or HOME mutation.
- Remote/checkouts cut over in order Musterroll → Undertake → Afterfact → Cautionlight.
- Use `gh repo rename -R TaylorFinklea/<old> <new> --yes`; GitHub ownership is unchanged.
- Route dotfile work through `chezmoi-base`; never run bare `chezmoi apply`.
- Do not push until the source gates and task reviews are green. Do not delete snapshots or old state roots.
- Every code task is RED-first and ends with a focused commit and task-scoped review.

---

### Task 1: Build the audited cutover inventory and transaction harness

**Files:**
- Create: `guildhall/scripts/four-tool-rename/manifest.json`
- Create: `guildhall/scripts/four-tool-rename/preflight.sh`
- Create: `guildhall/scripts/four-tool-rename/snapshot.sh`
- Create: `guildhall/scripts/four-tool-rename/rollback.sh`
- Create: `guildhall/scripts/four-tool-rename/test.sh`
- Modify: `guildhall/.docs/ai/current-state.md`

**Interfaces:**
- Produces: one canonical JSON mapping/inventory consumed by later cutover scripts.
- Produces: idempotent preflight/snapshot/rollback commands; no mutation command yet.
- Consumes: the approved spec `guildhall/.docs/ai/phases/four-tool-rename-spec.md`.

- [ ] **Step 0: Establish stacked isolated worktrees**

Create `/Users/tfinklea/git/.worktrees/four-tool-rename/{guildhall,bursar,conductor,hindsight,warden,chezmoi-base,chezmoi-personal}`. Guildhall, Bursar, Conductor, chezmoi-base, and chezmoi-personal branch `feat/four-tool-clean-rename` from their reviewed `feat/omp-role-aware-routing` heads; Hindsight and Warden branch from their clean `main` heads. Verify every new worktree is clean before editing. Preserve the role-routing worktrees unchanged.

- [ ] **Step 1: Write the failing manifest/preflight test**

Assert exactly four product mappings, dependency order, TaylorFinklea remotes, new checkout/config/state/report roots, exact paired backlog mappings (`backlog-bursar→backlog-musterroll`, `backlog-conductor→backlog-undertake`, `backlog-hindsight→backlog-afterfact`, `backlog-warden→backlog-cautionlight`), and explicit immutable-history paths. The test must reject wildcard directory exemptions.

```bash
bash scripts/four-tool-rename/test.sh
```

Expected before implementation: non-zero because `manifest.json` and commands do not exist.

- [ ] **Step 2: Inventory every mutation prerequisite without changing it**

The preflight must verify: clean relevant branches/worktrees; `gh auth status`; target slugs absent; source repositories and backlog repositories present; exact origins; installed old/new binaries; package/Homebrew/tap ownership; launch agents; active state/report roots; BWS project registrations by name only; and zero active Undertake/Conductor runs. Emit JSON; never print secret values.

```bash
scripts/four-tool-rename/preflight.sh --json > /tmp/four-tool-rename-preflight.json
jq -e '.ready == true and (.mappings | length) == 4' /tmp/four-tool-rename-preflight.json
```

Expected after implementation: `true` only when every non-mutating prerequisite is satisfied; otherwise typed blockers.

- [ ] **Step 3: Implement snapshot and rollback dry-run contracts**

`snapshot.sh` copies state/config/report metadata and records commit IDs, repository IDs, origins, installed binary hashes, and paths beneath an operator-selected snapshot directory. `rollback.sh --dry-run <snapshot>` prints the inverse operation order and refuses a missing/incomplete snapshot.

```bash
SNAP=$(mktemp -d)
scripts/four-tool-rename/snapshot.sh "$SNAP"
scripts/four-tool-rename/rollback.sh --dry-run "$SNAP"
```

Expected: snapshot manifest validates; dry-run lists Cautionlight→Afterfact→Undertake→Musterroll rollback and performs no mutation.

- [ ] **Step 4: Run focused tests and commit**

```bash
bash scripts/four-tool-rename/test.sh
git add scripts/four-tool-rename .docs/ai/current-state.md
git commit -m "chore: add four-tool rename transaction preflight"
```

---

### Task 2: Rename Bursar source and contracts to Musterroll

**Files:**
- Modify: `bursar/Cargo.toml`
- Modify: `bursar/Cargo.lock`
- Modify: `bursar/src/main.rs`
- Modify: `bursar/src/cli.rs`
- Modify: `bursar/src/observations.rs`
- Modify: `bursar/src/status.rs`
- Modify: `bursar/src/roster/mod.rs`
- Modify: `bursar/src/roster/snapshot.rs`
- Modify: `bursar/src/anthropic.rs`
- Modify: `bursar/roster.toml`
- Modify: `bursar/README.md`
- Modify: `bursar/tests/roster_snapshot.rs`
- Modify: `bursar/tests/status_json.rs`
- Modify: `bursar/tests/roster_migration.rs`
- Preserve: `bursar/tests/fixtures/roster/legacy-conductor.toml`

**Interfaces:**
- Produces: binary/package `musterroll`; schemas `musterroll/provider-observation@1`, `musterroll/status@2`, `musterroll/roster-config@2`, `musterroll/roster@2`.
- Produces: `MUSTERROLL_STATE_DIR`, default `~/.local/state/musterroll`, neutral `roster.toml`.
- Consumes: existing provider-observation semantics and strict roster-v2 invariants unchanged.

- [ ] **Step 1: Flip active contract assertions to the new identity**

Update existing CLI/status/roster tests to require `musterroll`, the new schema strings, new env var, and new state root. Keep the legacy fixture assertions explicitly old-name and path-allowlisted.

```bash
cargo test --test roster_snapshot --test status_json --test roster_migration
```

Expected before implementation: failures on package/CLI/schema/env/state assertions.

- [ ] **Step 2: Rename the package, binary, CLI, schemas, and state owner**

Follow the existing `cli`, `observations`, `status`, and `roster::snapshot` boundaries. Rename only product-prefixed identities; preserve provider IDs, observation semantics, exit codes, `roster.toml`, and provider HOME inputs such as `CLAUDE_CODE_OAUTH_TOKEN`.

```bash
cargo test --test roster_snapshot --test status_json --test roster_migration
```

Expected: focused tests pass; immutable legacy fixture still parses only through the migration test.

- [ ] **Step 3: Add one-shot live-ledger migration coverage**

Add a test fixture proving a copied old `provider-observations.jsonl` is rewritten into a new Musterroll-owned ledger envelope without changing provider/model evidence, timestamps, or expiry. The old file remains untouched.

```bash
cargo test migration
```

Expected: migrated state is readable only through new schemas; source fixture hash unchanged.

- [ ] **Step 4: Run full gates and commit**

```bash
cargo test
cargo clippy --all-targets -- -D warnings
cargo build --release
./target/release/musterroll roster snapshot --config roster.toml --json
./target/release/musterroll status --json
git add Cargo.toml Cargo.lock src tests roster.toml README.md
git commit -m "refactor: rename Bursar to Musterroll"
```

---

### Task 3: Rename Conductor source and contracts to Undertake

**Files:**
- Modify: `conductor/Cargo.toml`
- Modify: `conductor/Cargo.lock`
- Move: `conductor/conductor.toml` → `conductor/undertake.toml`
- Modify: `conductor/src/cli.rs`
- Modify: `conductor/src/config.rs`
- Move: `conductor/src/bursar.rs` → `conductor/src/musterroll.rs`
- Modify: `conductor/src/main.rs`
- Modify: `conductor/src/run.rs`
- Modify: `conductor/src/plan.rs`
- Modify: `conductor/src/plan_job.rs`
- Modify: `conductor/src/loop.rs`
- Modify: `conductor/src/deck.rs`
- Modify: `conductor/src/dispatch.rs`
- Modify: `conductor/src/dispatch_cycle.rs`
- Modify: `conductor/src/adversarial.rs`
- Modify: `conductor/src/cycle.rs`
- Modify: `conductor/src/config.rs`
- Modify: `conductor/src/ratchet.rs`
- Modify: `conductor/src/quarantine.rs`
- Modify: `conductor/src/bd.rs`
- Modify: `conductor/README.md`
- Modify: active tests and current handoff files

**Interfaces:**
- Produces: package/binary `undertake`, config `undertake.toml`, `UNDERTAKE_*` env vars, state `~/.local/state/undertake`, reports `~/.harness/reports/undertake`.
- Produces: active schemas `undertake/run@2`, `undertake/event@2`, `undertake/loop@1`, and Undertake-owned plan/review/approval/promotion schemas.
- Consumes: `musterroll status`, `musterroll roster snapshot`, `musterroll observe`; strict Musterroll schemas.

- [ ] **Step 1: Add/flip RED identity tests at existing seams**

Use existing tests in `cli`, `config`, `deck`, `run`, `plan_job`, `dispatch_cycle`, and the renamed Musterroll client. Require new help/version/config/env/state/report/schema/source strings and assert operational output contains no `conductor` or `bursar` token.

```bash
cargo test cli::tests config::tests deck::tests run::tests plan_job::tests
```

Expected before implementation: failures on old identities.

- [ ] **Step 2: Rename the crate, binary, config, module, and subprocess client**

Use LSP rename for the exported `bursar` module/types and LSP file rename where supported. Preserve authority and routing behavior. `CommandMusterrollClient` must issue `musterroll status --json`, `musterroll roster snapshot --json`, and the existing typed observation arguments under the `musterroll observe` subcommand; focused argv tests define every observation flag and value.

- [ ] **Step 3: Rename active schemas and operational namespaces**

Update active run/event/loop/authorization/report/project/harness strings, worker receipt/socket names, Bead metadata keys, default config/state/report paths, and source label `undertake-runtime`. Do not change archived v1/v2 fixture bytes designated in Task 1’s allowlist.

```bash
cargo test run::tests deck::tests dispatch_cycle::tests adversarial::tests plan_job::tests
```

Expected: strict rejection tests reject old schemas; new schemas round-trip.

- [ ] **Step 4: Add one-shot scheduler/live-state migration tests**

Cover scheduler lane state, reservations, journal, ratchet, plans, and current `runs-v2`. Require zero in-flight jobs. Rewrite only ownership envelopes/paths needed by Undertake; archived completed payloads remain under the old snapshot root and are not scanned.

```bash
cargo test migration reconciliation capacity
```

Expected: live policy/reservations survive, scores do not rewind, old snapshot remains unchanged, no dual read.

- [ ] **Step 5: Run full gates and commit**

```bash
cargo test
cargo clippy --all-targets -- -D warnings
cargo build --release
PATH="../bursar/target/release:$PATH" ./target/release/undertake config check --config undertake.toml
git add -A
git commit -m "refactor: rename Conductor to Undertake"
```

---

### Task 4: Rename Hindsight source, database owner, and ingest to Afterfact

**Files:**
- Modify: `hindsight/Cargo.toml`
- Modify: `hindsight/Cargo.lock`
- Modify: `hindsight/src/main.rs`
- Modify: `hindsight/src/cli.rs`
- Modify: `hindsight/src/config.rs`
- Modify: `hindsight/src/event.rs`
- Modify: `hindsight/src/recap.rs`
- Modify: `hindsight/src/ingest.rs`
- Modify: `hindsight/src/deck.rs`
- Modify: `hindsight/src/store.rs`
- Move: `hindsight/src/sources/conductor.rs` → `hindsight/src/sources/undertake.rs`
- Modify: `hindsight/src/sources/mod.rs`
- Rename current Undertake parser fixtures beneath `hindsight/tests/fixtures/conductor/`
- Modify: `hindsight/tests/events_cli.rs`
- Modify: `hindsight/tests/recap_smoke.rs`
- Preserve: historical event/source values inside migrated SQLite rows

**Interfaces:**
- Produces: package/binary `afterfact`, event schema `afterfact/event@2`, report project/harness `afterfact`, default DB `~/.local/share/afterfact/afterfact.sqlite3`.
- Consumes: `undertake/run@2` and `undertake/event@2` from `~/.local/state/undertake`.
- Produces: unchanged evidence semantics and source labels for historical rows; current new rows use Undertake/Afterfact identities.

- [ ] **Step 1: Flip CLI, report, source-root, schema, and DB tests to new identities**

```bash
cargo test events_cli recap_smoke store sources::undertake
```

Expected before implementation: old `hindsight`/`conductor` identity failures.

- [ ] **Step 2: Rename package/binary, CLI, config roots, reports, and parser module**

Preserve normalized event fields and redaction. Rename product-owned env vars to `AFTERFACT_*`, the Undertake source root field, and current parser gaps. Historical source values in existing DB rows remain factual.

- [ ] **Step 3: Implement tested SQLite copy migration**

Copy the source DB to the new path before opening it. Change the SQLite application ID to a new Afterfact constant and preserve schema version/table data. Rename the current migration filename `0003_conductor_reviewer.sql` only if the migration loader keys by filename safely; never alter already-applied SQL semantics.

```bash
cargo test store migration
```

Expected: row counts and content hashes match; application ID and owner path are new; original DB hash unchanged.

- [ ] **Step 4: Run full gates and commit**

```bash
cargo test
cargo clippy --all-targets -- -D warnings
cargo build --release
./target/release/afterfact db integrity-check
git add -A
git commit -m "refactor: rename Hindsight to Afterfact"
```

---

### Task 5: Rename Warden policy consumer to Cautionlight

**Files:**
- Modify: `warden/Cargo.toml`
- Modify: `warden/Cargo.lock`
- Modify: `warden/core/Cargo.toml`
- Modify: `warden/core/src/main.rs`
- Modify: `warden/core/src/lib.rs`
- Modify: `warden/core/src/policy.rs`
- Modify: `warden/core/src/audit.rs`
- Modify: `warden/core/tests/findings.rs`
- Modify: current `warden/README.md` and operational docs
- Classify separately: `warden/adapters/claude_pretooluse/**` historical/experimental adapter

**Interfaces:**
- Produces: package/binary `cautionlight`, finding schema `cautionlight/finding@1`, rule IDs `cautionlight.*`.
- Consumes: `afterfact/event@2` JSONL.
- Preserves: host-neutral policy semantics, finding evidence, exit codes 0/1/2.

- [ ] **Step 1: Flip supported CLI and finding tests to new identities**

```bash
cargo test -p warden
```

Expected before implementation: failures requiring package/binary/input schema/finding/rule rename. After `Cargo.toml` flips, use `cargo test -p cautionlight`.

- [ ] **Step 2: Rename the supported core package, binary, schemas, and rules**

Keep classification and policy decisions identical. The only supported operational command becomes:

```console
cautionlight inspect --stdin
```

It accepts only `afterfact/event@2` and emits only `cautionlight/finding@1`.

- [ ] **Step 3: Apply the historical adapter boundary**

If Task 1 allowlists `adapters/claude_pretooluse` as dated experimental evidence, leave its bytes and old package name unchanged and exclude it from the default operational build/install. Otherwise rename it consistently and prove it is current. Do not silently mix the two classifications.

- [ ] **Step 4: Run full gates and commit**

```bash
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
cargo build --release -p cautionlight
./target/release/cautionlight inspect --help
git add -A
git commit -m "refactor: rename Warden to Cautionlight"
```

---

### Task 6: Cut Guildhall’s current contract and demos to the four new names

**Files:**
- Modify: `guildhall/README.md`
- Modify: `guildhall/USAGE.md`
- Modify: `guildhall/demo/README.md`
- Modify: `guildhall/demo/run.sh`
- Modify: `guildhall/.docs/ai/phases/conductor-core-consolidation-spec.md`
- Modify: `guildhall/.docs/ai/phases/conductor-core-consolidation-plan.md`
- Modify: `guildhall/.docs/ai/phases/guildhall-integration-v1-spec.md`
- Modify: `guildhall/.docs/ai/phases/orchestration-runbook.md`
- Modify: `guildhall/.docs/ai/phases/bd-create-conductor-core-consolidation.sh`
- Modify: `guildhall/.docs/ai/phases/test-bd-create-conductor-core-consolidation.sh`
- Modify: `guildhall/.docs/ai/{current-state.md,roadmap.md}`
- Create: `guildhall/.docs/ai/decisions.md` entry mapping historical names

**Interfaces:**
- Consumes: four renamed binaries/repos/config/state/report contracts.
- Produces: current suite registry, demo, generator, runbook, and path-level immutable-history allowlist.

- [ ] **Step 1: Flip generator/demo tests to exact new names and paths**

```bash
bash .docs/ai/phases/test-bd-create-conductor-core-consolidation.sh
bash demo/run.sh --help
```

Expected before implementation: old-name expectation failures.

- [ ] **Step 2: Rename active suite contracts and generator outputs**

Update operational IDs, titles, descriptions, verify commands, repo roots, and command examples. Preserve closed historical Bead IDs only in the explicit `HISTORICAL_CLOSED_IDS` allowlist.

- [ ] **Step 3: Add scoped stale-name enforcement**

Extend `scripts/four-tool-rename/test.sh` to scan current files and subtract only exact allowlisted paths. It must fail if any old token appears in an active file or if an allowlist entry is a directory wildcard.

- [ ] **Step 4: Verify and commit**

```bash
bash .docs/ai/phases/test-bd-create-conductor-core-consolidation.sh
bash scripts/four-tool-rename/test.sh
bash demo/run.sh --help
git add -A
git commit -m "docs: cut Guildhall over to renamed tools"
```

---

### Task 7: Cut managed routing, skills, Ralph, and scorecard source to new names

**Files:**
- Modify in `chezmoi-personal`: `AGENTS.md`
- Modify: `.skills-src/skills/{guildhall-orchestration,delegate,dispatch-to-pi,fallback-orchestration}.md`
- Modify: `dot_claude/skills/loops/SKILL.md`
- Modify: four `guildhall-orchestration/SKILL.md.tmpl` sister templates
- Modify: four `delegate/references/panels.md` sister assets
- Modify: `dot_agents/skills/guildhall-orchestration/agents/openai.yaml`
- Modify: `private_dot_local/bin/executable_ralph`
- Modify: `private_dot_local/lib/scorecard/gen-scorecard-digest.mjs`
- Modify: `private_dot_local/lib/scorecard/gen-scorecard-digest.test.mjs`
- Modify: `scripts/tests/test_restore_beads_backlogs.sh`
- Modify: `.chezmoiremove` only for verified old managed live files
- Verify in `chezmoi-base`: composition/public-safety ownership, no product content changes unless routing requires them

**Interfaces:**
- Produces: managed commands/paths using Undertake/Musterroll/Afterfact/Cautionlight; Ralph default `/Users/tfinklea/git/undertake/undertake.toml`.
- Produces: `UNDERTAKE_ROSTER` as the renamed scorecard-generator override; `RALPH_ROSTER` remains the neutral Ralph override.
- Consumes: source branches only; no HOME mutation in this task.

- [ ] **Step 1: Flip parity, scorecard, Ralph, and backlog tests to new names**

```bash
bash scripts/tests/test_skill_sister_parity.sh
node --test private_dot_local/lib/scorecard/gen-scorecard-digest.test.mjs
bash scripts/tests/test_restore_beads_backlogs.sh
```

Expected before implementation: failures on old current paths/commands/project IDs.

- [ ] **Step 2: Update canonical skill bodies and generated sister assets**

Edit the canonical `.skills-src` bodies first; keep one-line include templates. Update duplicated panel assets identically and preserve the skill identity `guildhall-orchestration`.

- [ ] **Step 3: Update Ralph, scorecard, removals, and managed operational prose**

Replace product-prefixed env/default paths consistently. Do not rename neutral model-scorecard files or LaunchAgent labels. Add `.chezmoiremove` entries only after render output proves an old managed target would remain live.

- [ ] **Step 4: Run source/render gates and commit**

```bash
bash scripts/tests/test_skill_sister_parity.sh
node --test private_dot_local/lib/scorecard/gen-scorecard-digest.test.mjs
bash scripts/tests/test_restore_beads_backlogs.sh
bash scripts/tests/test_ralph_pi_liveness.sh
bash scripts/tests/test_omp_worker.sh
git add -A
git commit -m "refactor: route Guildhall through renamed tools"
```

From `chezmoi-base`:

```bash
python3 scripts/check-public-safety.py
python3 tests/test-public-safety.py
bash tests/test-compose.sh
scripts/chezmoi-compose preflight personal
scripts/chezmoi-compose diff personal
```

Expected: clean ownership/parity and a reviewed diff; no apply.

---

### Task 8: Integrate all source branches and prove the new-only suite locally

**Files:**
- Modify only integration defects found in Tasks 2–7; no new compatibility layer.
- Update: `guildhall/scripts/four-tool-rename/manifest.json` with exact verified package/remote/backlog/install facts.

**Interfaces:**
- Consumes: all source commits.
- Produces: locally runnable new-only suite and immutable release candidates.

- [ ] **Step 1: Install release binaries into an isolated temporary PATH**

```bash
BIN=$(mktemp -d)
cp ../bursar/target/release/musterroll "$BIN/"
cp ../conductor/target/release/undertake "$BIN/"
cp /Users/tfinklea/git/hindsight/target/release/afterfact "$BIN/"
cp /Users/tfinklea/git/warden/target/release/cautionlight "$BIN/"
PATH="$BIN:$PATH" undertake config check --config ../conductor/undertake.toml
```

Expected: config valid; preflight finds `musterroll`, `afterfact`, and `cautionlight`; no old binary is consulted.

- [ ] **Step 2: Run the no-spend cross-suite lifecycle**

Use isolated HOME/state/report roots. Define exact disposable inputs, prepare/cancel or fake-dispatch an Undertake `plan`, ingest its events with Afterfact, then pipe Afterfact events into Cautionlight.

```bash
TARGET=$(mktemp -d)
REQUEST=$(mktemp)
printf '%s\n' 'Plan a read-only GET /healthz endpoint; all decisions are resolved and open_questions must be empty.' > \"$REQUEST\"
PATH=\"$BIN:$PATH\" undertake plan prepare --repo \"$TARGET\" --artifact \"$REQUEST\" --output-kind spec --tier-floor lead --complexity XL --config ../conductor/undertake.toml
PATH=\"$BIN:$PATH\" afterfact db ingest
PATH=\"$BIN:$PATH\" afterfact events --since 24h | cautionlight inspect --stdin
```

Expected: only new schema/project/state namespaces; every invocation correlates; Cautionlight emits advisory output or a documented no-finding exit without schema failure.

- [ ] **Step 3: Run all repository and stale-name gates**

```bash
bash guildhall/scripts/four-tool-rename/test.sh
cargo test && cargo clippy --all-targets -- -D warnings
```

Run the latter in each Rust repository with its repository-specific workspace flags. Re-run managed parity/render gates.

- [ ] **Step 4: Conduct task and cross-repo reviews**

Require spec/quality approval for each source task, then one different-family Lead review of the integrated source. Fix every confidence ≥80 finding with RED-first coverage and re-review.

---

### Task 9: Quiesce, snapshot, and rename GitHub repositories and backlog repositories

**Files:**
- Runtime artifacts only: snapshot directory and Git remote configuration.
- No source edits unless verification exposes a missed current reference.

**Interfaces:**
- Consumes: green integrated source and Task 1 transaction harness.
- Produces: renamed GitHub repositories and exact rollback metadata.

- [ ] **Step 1: Re-run destructive-operation preflight and obtain the final snapshot**

```bash
scripts/four-tool-rename/preflight.sh --json
SNAP="$HOME/.local/state/guildhall/rename-snapshots/$(date -u +%Y%m%dT%H%M%SZ)"
scripts/four-tool-rename/snapshot.sh "$SNAP"
```

Expected: zero in-flight jobs; all branches clean; targets available; snapshot valid.

- [ ] **Step 2: Push reviewed source branches without changing default branches**

Push each feature branch explicitly. Do not force-push. Record remote SHAs in the snapshot.

- [ ] **Step 3: Rename remotes in dependency order**

```bash
gh repo rename -R TaylorFinklea/bursar musterroll --yes
gh repo rename -R TaylorFinklea/conductor undertake --yes
gh repo rename -R TaylorFinklea/hindsight afterfact --yes
gh repo rename -R TaylorFinklea/warden cautionlight --yes
```

Rename the four paired backlog repositories in the same dependency order. Preflight must prove all four exist before this step:

```bash
gh repo rename -R TaylorFinklea/backlog-bursar backlog-musterroll --yes
gh repo rename -R TaylorFinklea/backlog-conductor backlog-undertake --yes
gh repo rename -R TaylorFinklea/backlog-hindsight backlog-afterfact --yes
gh repo rename -R TaylorFinklea/backlog-warden backlog-cautionlight --yes
```

Stop and invoke rollback on the first failure.

- [ ] **Step 4: Verify repository IDs, slugs, redirects, and pushed commits**

```bash
gh repo view TaylorFinklea/musterroll --json id,name,url
gh repo view TaylorFinklea/undertake --json id,name,url
gh repo view TaylorFinklea/afterfact --json id,name,url
gh repo view TaylorFinklea/cautionlight --json id,name,url
```

Expected: names changed, repository IDs match snapshot, reviewed commits present.

---

### Task 10: Rename local checkouts/worktrees and update origins

**Files:**
- Local Git worktree metadata and origins.
- Managed path references already prepared in source.

**Interfaces:**
- Consumes: renamed remotes.
- Produces: `/Users/tfinklea/git/{musterroll,undertake,afterfact,cautionlight}` with exact new origins.

- [ ] **Step 1: Move from a neutral parent directory**

Do not move a checkout while a shell/process is inside it. Preserve feature branches and registered worktrees; use `git worktree move` for registered linked worktrees and filesystem rename only for primary worktrees when Git metadata remains valid.

- [ ] **Step 2: Set exact origins**

```bash
git -C /Users/tfinklea/git/musterroll remote set-url origin git@github.com:TaylorFinklea/musterroll.git
git -C /Users/tfinklea/git/undertake remote set-url origin git@github.com:TaylorFinklea/undertake.git
git -C /Users/tfinklea/git/afterfact remote set-url origin git@github.com:TaylorFinklea/afterfact.git
git -C /Users/tfinklea/git/cautionlight remote set-url origin git@github.com:TaylorFinklea/cautionlight.git
```

- [ ] **Step 3: Verify worktree registrations and branches**

```bash
git -C /Users/tfinklea/git/undertake worktree list --porcelain
git -C /Users/tfinklea/git/musterroll worktree list --porcelain
```

Repeat for all four. Expected: no path under an old primary checkout; feature commits retained; statuses clean.

---

### Task 11: Migrate live state, install distributions, and publish managed HOME

**Files:**
- New operational state/report roots.
- Local release binaries from Tasks 2–5; current source inventory found no repository-owned package registry, formula, tap, or release workflow.
- Composed HOME targets from Task 7.

**Interfaces:**
- Consumes: snapshot, new checkouts, release binaries, green chezmoi diff.
- Produces: installed new suite and archived old state; no old live executable/config reader.

- [ ] **Step 1: Run one-shot state migrations against copies**

Migrate Musterroll observations, Undertake scheduler/current policy, Afterfact DB, and Cautionlight current cursor/config. Validate counts, hashes, schemas, and new owners before switching paths. Keep old roots read-only under the snapshot/archive location.

- [ ] **Step 2: Install the four local release artifacts**

Task 1 must encode `distribution.kind = "local-release-copy"` and fail closed if preflight discovers a conflicting registry/tap owner, which requires revising this plan before mutation. Install exact verified release binaries:

```bash
install -m 0755 /Users/tfinklea/git/musterroll/target/release/musterroll \"$HOME/.local/bin/musterroll\"
install -m 0755 /Users/tfinklea/git/undertake/target/release/undertake \"$HOME/.local/bin/undertake\"
install -m 0755 /Users/tfinklea/git/afterfact/target/release/afterfact \"$HOME/.local/bin/afterfact\"
install -m 0755 /Users/tfinklea/git/cautionlight/target/release/cautionlight \"$HOME/.local/bin/cautionlight\"
```

Record source SHA-256 and installed SHA-256 equality in the snapshot. Old binaries remain in the rollback snapshot until the final gate, then are removed from live PATH without deletion.

- [ ] **Step 3: Apply managed HOME once through composition**

```bash
cd /Users/tfinklea/git/chezmoi-base
scripts/chezmoi-compose preflight personal
scripts/chezmoi-compose diff personal
scripts/chezmoi-compose sync personal
```

Use the wrapper’s reviewed targeted apply path; never bare `chezmoi apply`.

- [ ] **Step 4: Verify PATH and absence of old live names**

```bash
command -v undertake
command -v musterroll
command -v afterfact
command -v cautionlight
```

Expected: each resolves to the approved installed artifact. `command -v conductor`, `bursar`, `hindsight`, and `warden` must not resolve. Active config/state/report/skill paths contain only new names.

---

### Task 12: Run the approved live gate, final review, and resume operations

**Files:**
- Live run/report/state evidence only.
- Update current handoff/roadmap and suite mapping ADRs after success.

**Interfaces:**
- Consumes: fully cut-over installed suite.
- Produces: accepted new-namespace evidence, final report, closed rename backlog items.

- [ ] **Step 1: Run final preflight and prepare an immutable disposable target**

```bash
undertake config check --config /Users/tfinklea/git/undertake/undertake.toml
musterroll status --json
musterroll roster snapshot --config /Users/tfinklea/git/musterroll/roster.toml --json
```

Expected: valid role-policy contingencies and writable new state; no old path in evidence.

- [ ] **Step 2: Obtain exact run approval and dispatch provider-distinct `plan` stages**

Require author, peer, and second opinion from three distinct Musterroll ProviderIds. The immutable request must be grounded in the disposable target and have no open product questions.

- [ ] **Step 3: Verify Afterfact and Cautionlight correlation**

```bash
afterfact db ingest
afterfact events --since 24h | cautionlight inspect --stdin
```

Expected: every Undertake invocation correlates; Afterfact/Cautionlight schemas only; advisory processing is read-only.

- [ ] **Step 4: Verify immutable target and namespace purge**

Confirm terminal accepted outcome, unchanged target commit, empty target status, and final smoke tests. Run the scoped stale-name scanner; old names may appear only in path-level immutable-history allowlist entries and archived snapshot content.

- [ ] **Step 5: Run final different-family review and complete records**

Require SPEC yes, QUALITY yes, and zero confidence ≥80 blockers across all source repos, remote/checkouts, state/distribution, and managed HOME. Update current roadmaps/handoffs, close Beads, publish a harness-deck completion report, and resume Undertake dispatch. Preserve rollback snapshots; do not delete historical evidence.
