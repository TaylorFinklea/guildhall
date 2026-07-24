# Four-tool clean rename specification

**Status:** design approved 2026-07-24; implementation planning pending

## Goal

Rename the four operational Guildhall tools as one dependency-ordered transaction:

| Current | Replacement | Role |
|---|---|---|
| Conductor | Undertake | approved-job orchestration and verified execution |
| Bursar | Musterroll | execution-profile roster and provider availability |
| Hindsight | Afterfact | evidence ingestion, attribution, and scorecards |
| Warden | Cautionlight | read-only advisory findings |

Brand decisions were approved on 2026-07-20. The completed role-aware `plan` lifecycle and accepted three-provider live run clear the prior P0 gate.

## Product contract

- Exact lowercase operational names: `undertake`, `musterroll`, `afterfact`, `cautionlight`.
- Clean break. No old CLI wrappers, deprecated aliases, schema aliases, duplicate config lookup, or dual state-root reads.
- Replace current executable, package/crate, config, state/report namespace, schema owner, skill, test, repository slug, checkout path, origin, installed binary, package/formula, and managed-HOME references.
- Cross-tool authority remains unchanged. Naming does not move responsibilities between products.
- Current CLI job vocabulary follows the shipped native job set. Undertake exposes `work`, `review`, `consult`, and `plan`; retired Arena does not return.
- Brand line for Undertake: “Take one approved job through verified completion.”

## Historical boundary

Preserve immutable history:

- Git history is never rewritten.
- Dated completed plans, ADRs, reports, archived run payloads, and historical source labels retain the names that were true when recorded.
- Add one current mapping ADR in each affected repository, or one suite ADR referenced by each repository, so readers can resolve historical names.
- Current operational docs, examples, help, templates, fixtures, generated output, and active handoff state use only new names.
- A checked stale-name allowlist names every intentionally preserved historical path. Broad prose exceptions are forbidden.

## Surfaces

### Source repositories

For each tool:

- Rename every existing crate/package and binary target whose current name is one of the four product names; neutral library/package names remain unchanged.
- Rename source-level product strings, CLI usage, product-prefixed environment variables, default paths, product-named config files, report project/harness identifiers, event/run schemas, fixtures, snapshots, tests, and current documentation.
- Rename `conductor.toml` to `undertake.toml`. Keep neutral configuration names such as Musterroll’s `roster.toml` unchanged.
- Rename operational state roots under `~/.local/state`, report roots under `~/.harness/reports`, and any cache/log/lease roots owned by the product.
- Update cross-repository imports, executable invocations, absolute paths, health/preflight checks, and dependency contracts.

### Repository and distribution surfaces

- GitHub slugs become `undertake`, `musterroll`, `afterfact`, and `cautionlight` in the existing owner organization/account.
- Local primary checkouts use the same lowercase directory names.
- Feature worktrees are retargeted or recreated without losing commits.
- Origins point to the renamed remotes and are verified after GitHub redirects are no longer needed operationally.
- Package, release, and Homebrew metadata use new names. Existing old-name publications are not silently overwritten; the plan must inventory registries/taps and define the available rename mechanism before mutation.
- Installed binaries and managed PATH entries use only new names after the cutover gate.

### Managed configuration

Route all dotfile changes through `chezmoi-base`; place personal-only surfaces in `chezmoi-personal` under its routing rules.

Update:

- canonical AGENTS instructions and generated harness copies;
- Guildhall orchestration, loop, delegation, readiness, review, and related skills;
- Ralph roster defaults and helper scripts;
- model-scorecard generator paths and labels;
- MCP/harness configuration and project trust paths;
- managed removal directives for retired old-name live files;
- parity and render tests.

One reviewed `chezmoi apply` occurs only after source, remote, checkout, state-migration, and distribution gates are green.

## Dependency-ordered transaction

### Prepare

1. Verify every worktree is clean and all rename branches contain the completed role-aware cutover.
2. Verify GitHub authentication/ownership and exact target-slug availability.
3. Inventory package registries, release workflows, taps/formulae, installed binaries, launch agents, state roots, report roots, secrets registrations, and absolute paths.
4. Produce a machine-readable old→new reference inventory and immutable-history allowlist.
5. Build and test all four source cutovers in isolation using only new names.
6. Prepare rollback commands and snapshots before any remote or HOME mutation.

### Quiesce

1. Stop new Undertake/Conductor dispatches.
2. Require zero in-flight work, review, consult, or plan runs.
3. Snapshot all four operational state roots, managed configuration, installed binaries, origins, and repository metadata.
4. Record current commit IDs and remote repository IDs.

### Cut over

Rename remote repositories and local primary checkouts in dependency order:

1. Bursar → Musterroll
2. Conductor → Undertake
3. Hindsight → Afterfact
4. Warden → Cautionlight

Then update origins, cross-repository paths, distribution metadata, installed binaries, and managed configuration. This order makes the roster provider available before the orchestrator, then restores evidence ingestion before advisory consumption.

### Publish

1. Apply the reviewed managed-HOME diff once.
2. Verify new binaries resolve on PATH and old binaries do not.
3. Run the full cross-suite verification gate.
4. Archive old operational state roots only after the new suite passes.
5. Resume dispatch only after final review confirms no mixed live contract.

## State and evidence migration

Snapshot first; never transform the only copy.

New operational roots use only the replacement names. A one-shot migration carries forward only live state:

- Musterroll provider observations, bounded approvals, and eligibility facts;
- Undertake scheduler reservations required for recovery and current policy state;
- Afterfact’s evidence database and scorecard state;
- Cautionlight advisory configuration and current cursor/checkpoint state.

Migration rewrites only ownership envelopes, schema namespaces, and operational paths required by the new binaries. Historical payloads and historical source labels remain factual.

Completed runs and other immutable evidence are archived under dated, read-only old-name roots. New binaries do not scan those roots. There is no dual-read fallback.

The cutover requires zero in-flight jobs, so no live worker process or partially completed stage is translated. If quiescence cannot be proven, the transaction stops before remote mutation.

## Failure and rollback

- Before HOME publication: revert source branches, remote slugs, checkout names, origins, and distribution metadata to the captured pre-cutover state.
- After HOME publication: restore state/config snapshots and all four old remote/checkouts as one coordinated rollback; do not leave a mixed suite.
- Any missing registry rename mechanism, unavailable target slug, dirty worktree, in-flight run, schema migration failure, or stale operational reference is a hard stop.
- Unreadable or owner-unknown state is fail-closed and preserved for diagnosis; it is not guessed into a new namespace.
- No partial success is reported.

## Verification

### Per repository

- Full tests, strict lint/Clippy, build, and package checks pass under the new crate/package/binary name.
- CLI `--help`, `--version`, errors, fixtures, and snapshots expose only the replacement name.
- Repository-specific current docs and handoff state expose only the replacement name.

### Cross-suite

- `undertake config check --config /Users/tfinklea/git/undertake/undertake.toml` passes against Musterroll.
- Musterroll roster snapshot/status and Undertake role-policy contingency checks pass.
- Undertake completes a no-spend `plan` lifecycle using only new config, state, event, and report namespaces.
- Afterfact ingests and correlates every Undertake attempt.
- Cautionlight consumes Afterfact evidence read-only and emits its advisory result.
- GitHub repository views, origins, checkout paths, installed binaries, PATH, package/formula metadata, managed skill parity, and `chezmoi diff` expose only new operational names.
- Scoped stale-name scans find old names only in the explicit immutable-history allowlist.

### Live gate

Run one explicitly approved disposable Undertake `plan` through provider-distinct author, peer, and second-opinion stages. Require:

- terminal accepted outcome;
- exact Musterroll profile attribution;
- Afterfact correlation for every invocation;
- Cautionlight read-only consumption;
- unchanged target commit and clean target worktree;
- only new event/report/state namespaces;
- no old executable, config, state reader, or operational path used.

### Final review

A different-family Lead reviewer inspects all four source repositories plus Guildhall and managed dotfile changes. Completion requires no confidence ≥80 blocker and no mixed live contract.

## Non-goals

- Changing tool responsibilities or routing policy.
- Reintroducing Arena or any retired job.
- Rewriting Git history or archived evidence.
- Adding compatibility aliases.
- Refactoring unrelated code during the rename.
- Publishing portfolio/marketing material beyond repository and package metadata required for the cutover.

## Acceptance

The rename is complete only when all four new repositories, checkouts, binaries, configs, state roots, schemas, reports, packages, and managed references are operational together; the approved live gate passes; old operational names remain only in the explicit historical allowlist; rollback artifacts exist; and dispatch resumes under Undertake with Musterroll, Afterfact, and Cautionlight.