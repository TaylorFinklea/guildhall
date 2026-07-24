# Guildhall

Guildhall is the charter, contract, and migration-history repository for four
Unix-style AI engineering tools. Product code lives in the member repositories;
this repository owns suite-wide invariants and the cross-tool operating model.

## Current suite

| Tool | Responsibility | Repository |
|---|---|---|
| **Undertake** | Take one approved job through verified completion. | `~/git/undertake` |
| **Musterroll** | Publish configured execution profiles and current provider eligibility. | `~/git/musterroll` |
| **Afterfact** | Ingest evidence, attribute work, and derive scorecards. | `~/git/afterfact` |
| **Cautionlight** | Read Afterfact events and emit advisory findings without writes. | `~/git/cautionlight` |

The process boundary is explicit:

```text
human approval -> Undertake
Musterroll roster/eligibility -> Undertake
Undertake run artifacts -> Afterfact -> Cautionlight
Afterfact recommendations -> human review -> Musterroll configuration
```

No scorecard or finding changes routing automatically.

## Suite-wide invariants

1. **Closed roster.** Only standing pre-authorized execution profiles receive work.
2. **Hard ownership floor.** `tier_floor` is enforced before assignment.
3. **Fail closed.** Unknown schema, identity, eligibility, approval, verifier, or artifact hash stops the operation.
4. **Artifacts are evidence.** Exit status is testimony; durable, hash-pinned artifacts decide completion.
5. **One writer per repository.** Parallel work is cross-repository only.
6. **No push or unmanaged HOME mutation.** Managed configuration is reviewed and applied through its owning repository.
7. **Budget with the plan.** Approval includes explicit concurrency and spend caps.
8. **Coverage gaps stay visible.** Missing evidence is never reported as success.
9. **Routing metadata is canonical.** `tier_floor`, `complexity`, and `verify_cmd` live in Bead metadata.

## Contracts

- Musterroll emits strict roster and status records.
- Undertake pins the exact roster snapshot, target, approval, role/stage bindings,
  limits, attempts, verifier results, and terminal outcome in durable run artifacts.
- Afterfact treats raw harness artifacts, Git, Undertake run artifacts, and its
  append-only observation journal as canonical; its SQLite database is rebuildable.
- Cautionlight is stateless and read-only. Findings are advice, never enforcement.
- stdout JSONL is a permitted live-query view only when it identifies its durable
  source artifact; the artifact remains authoritative.

## Operator entry points

1. Read `~/AGENTS.md`.
2. Read `.docs/ai/current-state.md` and `.docs/ai/roadmap.md`.
3. Read `.docs/ai/phases/undertake-core-consolidation-spec.md` for architecture.
4. Use `USAGE.md` and `demo/run.sh --help` for current commands.
5. Use `.docs/ai/decisions.md` to resolve historical terminology.
