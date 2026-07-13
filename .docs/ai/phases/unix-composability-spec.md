# Guildhall suite composability — v1 spec

**Status**: design approved 2026-07-13 (user). Fourth thrust; amends the
[2026-07-03] month-focus ADR. Adversarially reviewed by a 3-model panel
(glm-5.2 red-team, qwen3.7-max evidence, minimax-m3 gap) — the panel materially
changed this design; see § What the panel changed.

## Problem

The suite is not invokable and its one cross-member integration fails open.

`command -v` finds **none** of the eight members — only `harness-deck`, `bd`, and
`ralph`. Every member is reachable only as `~/git/<member>/target/release/<member>`;
warden and provenance are not even built. The owner's goal — *"actually start using
this suite, and know exactly what each one does and how to use it"* — is blocked a
rung below composability.

## Verified findings

Evidence grade is recorded per finding. **[V]** = verified directly in this session.
**[S]** = reported by a recon subagent that ran the command live; re-confirm at
implementation time before relying on the exact line number.

### C1 — Nothing is on PATH **[V]**

`command -v conductor bursar warden hindsight provenance gauntlet envoy foreman`
returns nothing. Only harness-deck / bd / ralph resolve.

### C2 — The budget gate fails open, and fail-open is the branch production is in **[V]**

- `conductor/src/config.rs:330` — `use_bursar: true` is the default.
- `conductor/src/bursar.rs:148` — `Command::new("bursar")`, resolved by bare name.
- bursar is not on PATH (C1) → `io::ErrorKind::NotFound` → `BursarError::unavailable`
  (`bursar.rs:154-157`).
- `conductor/src/bursar.rs:196-202` — `unavailable` → `BudgetAction::StaticCaps`.
- `conductor/src/dispatch_cycle.rs:660` — `StaticCaps` renders as **`CalloutLevel::Info`**.
- But `bursar.rs:203-209` + `:231-240` — bursar *present* and reporting
  `unknown`/`error` → `SpendCautiously` → **`CalloutLevel::Warn`** (`dispatch_cycle.rs:661`).

**The safety tool being absent is ranked *safer* than the safety tool expressing
doubt.** The [2026-07-01] Bursar ADR was explicit that `unknown` must be
"spend-cautiously... never as 'plenty'." Nobody made **missing** fail closed, and
missing is the live state.

This is a charter invariant-3 violation ("fail closed everywhere"), not a
composability nit. It is the most serious finding in this document.

### C3 — Gauntlet forked the parser; provenance did not **[V]**

`grep hindsight gauntlet/Cargo.toml provenance/Cargo.toml` → no matches.

- **gauntlet** — `src/cost.rs` re-implements the pi-log parser (commits `9bd1b91`,
  `aa48729`, 2026-07-09) a week *after* hindsight's lib crate shipped (`03017d6`,
  2026-07-02). Violates gauntlet's own decisions.md ADR ("never fork parsers... reuse
  hindsight's when it ships") and the guildhall [2026-07-01] ingestion ADR ("parser
  forks are prohibited"). **Real defect.**
- **provenance** — `src/ingestion.rs` defines its own view structs over the serialized
  event shape, with no compile-time coupling to hindsight. **This is correct
  decoupling across a process boundary and is NOT a defect.** An earlier draft of this
  audit wrongly flagged it. Provenance's real gap is that its event source is still
  `FixtureEventSource` — it has no live source, because none is published (C4).

### C4 — The normalized event stream is never emitted **[V]**

`hindsight/src/recap.rs:244-263` builds `Vec<Event>`, folds it into aggregate tallies,
and drops it. `grep events hindsight/src/cli.rs` finds only a prose summary line. There
is no `hindsight events` subcommand. The event model the substrate principle is named
for exists only as a discarded in-memory intermediate.

**The cost of C4, measured [V].** Run live on this repo:

```
$ provenance annotate ~/git/guildhall
annotations: 147
uncorrelated commits: 38
$ git -C ~/git/guildhall log --oneline | wc -l
38
```

**38 commits. 38 uncorrelated. 100%.** Provenance — the member whose entire purpose is
"which model wrote this line, and was it ever reviewed?" — attributes *nothing*, because
it is still on `FixtureEventSource` and no live event source is published. It is a
working engine with no fuel line.

This is the justification for Slice 3, and it is stronger than any argument from
architecture: the pipe is not an aesthetic upgrade, it is the reason one of the six
members currently does nothing.

### C5 — Nobody handles SIGPIPE **[V]**

`grep -rn "SIGPIPE\|BrokenPipe" hindsight/src conductor/src bursar/src` → no matches.
Rust's runtime sets `SIGPIPE` to `SIG_IGN`, so a write to a closed pipe returns
`Err(BrokenPipe)` and `println!` panics on it. **Any streaming endpoint added to this
suite panics the first time it meets `| head`.** This is a defect in the *proposed*
work, found by the panel before a line was written.

### C6 — Exit codes: three real bugs, one non-bug **[S]**

- `bursar status` → exit **0** on a live HTTP 401. **Real** — and it is the second
  fail-open in the budget path.
- `conductor scan` → exit **1** on ordinary skips (a non-beads sibling repo in `~/git`).
  **Real** — "everything is fine" reports failure, so `conductor scan && …` is unusable.
- `warden-claude-pretooluse` → exit **0** on crash / malformed input / non-UTF-8 stdin
  (and emits zero bytes on stdout in that case). **Real, and a fail-open in a gate.**
- `warden-claude-pretooluse` → exit **0** on allow / ask / deny. **NOT a bug.** Claude
  Code's PreToolUse protocol reads `permissionDecision` from the stdout JSON, not from
  `$?`. Judging this on `$?` measures the wrong interface. Leave it.
- `provenance query unreviewed-junior` → exit 0 even when it flags hunks. Real but low;
  blocks CI gating only.

### C6b — `conductor config check` never checks bursar **[V]**

Run live: `conductor config check` verifies **ten** external tools — bd, pi, agy, claude,
codex, opencode, ralph, orchestra, bun, harness-deck — plus the state dir, and exits 0.
**It does not check `bursar`**, the one guild member conductor actually shells out to.

This is the direct answer to "why did nobody catch C2." The tool whose entire job is
*"will my dependencies resolve?"* omits the dependency that didn't. Adding bursar to the
preflight is a one-line change that would have caught the fail-open the day it appeared.

### C6c — `conductor scan` is cwd-dependent and has no `--config` **[V]**

`scan` is the only subcommand carrying `--json`, and the only one *without* `--config`
(confirmed against the binary's own usage string). It reads `conductor.toml` from the
process cwd, so from anywhere but `~/git/conductor` it exits 2 with "failed to read
conductor.toml". From the right cwd it emits 478 KB of clean JSON on stdout, empty
stderr — **and exits 1**, from ordinary `NotBeadsRepo` skips.

The suite's one machine-readable endpoint is the one you cannot point at a config, and
its exit code reports failure on a healthy fleet.

### C7 — The `harness-conductor` → `conductor` rename left live breakage **[V/S]**

`~/git/harness-conductor` does not exist **[V]**. Still referenced by guildhall's
README, `demo/run.sh` (the flagship command 404s), and a gauntlet golden task's
`origin_path` — so `gauntlet lint` exits 128 **[S]**.

### C8 — Read commands mutate **[S]**

`hindsight recap` writes a new `~/.harness/reports/hindsight/recap-<ts>/` on every
invocation, no suppress flag. `conductor cycle --dry-run` writes a report anyway.
`conductor arena run` auto-applies the winner by default. `gauntlet lint` /
`validate --smoke-run` do live `git worktree add/remove` against sibling repos — a
lint must be static.

### C9 — No `--help` on any member **[S]**

conductor, bursar, hindsight, provenance, gauntlet all hand-roll arg parsing with no
`--help` arm; `--help` falls into "unknown subcommand" and exits 1 or 2,
indistinguishable from a typo. Agents read `--help` too.

### Not defects — recorded so they stay dead

- **envoy** is a skill + envelope validator *by design*; **foreman** is spec-only and
  *deferred by ADR*. The suite is **six** binaries, not eight. Scoring them as missing
  tools was an error.
- **The demo script's 22 glue hacks** are in a *demo*. They are evidence of ergonomics,
  not of production architecture. Production composition is conductor's internal
  `Command::new(...)` + the disk bus.

## Architecture

### Roles, not a uniform filter grid

The earlier draft scored all members on eight Unix axes and reported "stdin is 0 for
every tool but warden" as the headline. **That was a category error.** A source has no
stdin. An orchestrator is not a filter. Axes are role-dependent:

| role | members | must do well | not applicable |
|---|---|---|---|
| source | bursar | machine-readable stdout, honest exit code | stdin, filtering |
| transform | hindsight, provenance | stdin **and** stdout — the only true filters | — |
| gate | warden | stdout JSON verdict; **fail closed on crash** | `$?` for allow/ask/deny |
| sink | harness-deck | accept input incl. stdin | passing data through |
| orchestrator | conductor | compose members; honest exit code | being a filter itself |

**Universal axes only:** single responsibility · no mutation on a read path · fail
closed on crash. Everything else is role-specific. Composite scores are abandoned —
they were, in the panel's words, "judgment dressed up as quantification."

### Two layers, not two interfaces

> **The disk artifact is the durable record. stdout is an ephemeral live-query view of
> it.** They are layers, not peers.

Precedence is explicit and one-directional: **the artifact wins.** A stdout view is
derived from the artifact, never the reverse, so the two cannot drift as competing
sources of truth. This is what makes the change charter-compatible rather than
charter-amending in spirit — but it still needs the one-line amendment recorded below,
because the [2026-07-01] substrate ADR says "exclusively through durable files."

### The stream carries the artifact's identity

Every stdout envelope carries a reference to the artifact it is a view of:

```
{"schema":"guildhall/<tool>@1", ..., "artifact":{"path":"<abs path>","sha256":"<hex>"}}
```

**Rationale (this is the load-bearing design rule).** The charter's scar — *"exit codes
are testimony; artifacts are evidence"* — was earned when `agy` exited 0 on
quota-exhausted no-ops. A naive `bursar check && dispatch` would re-introduce exactly
that failure mode: gating a money-spending action on an exit code from a tool already
observed to lie. Carrying the artifact reference means:

- A cheap consumer reads stdout and trusts the fast path.
- **A consumer about to spend money re-reads the artifact and verifies the hash.**
- Exit codes become a fast-path *hint*, never the sole gate.

The principle survives instead of eroding by convenience.

### The parser question — pipe, not crate

**Decision: share the format, not the crate.** `hindsight events --json` is the one
parser; every other member consumes its output. No member takes a Rust path-dependency
on hindsight.

A shared crate binds three independently-released repos into one build graph, serves
only Rust callers (envoy is bash), and — decisively — shipping a library coupling to
satisfy a Unix-composability mandate is self-defeating. The performance case is void at
human-and-cycle cadence. "Both" is the worst option: double the surface, double the
drift, for two consumers.

This satisfies the [2026-07-01] ingestion ADR's actual requirement (*one* parser, one
ground truth) by a different mechanism than the ADR anticipated. Amendment recorded.

## Work

Three slices. **Slice 1 is safety and ships first, alone, tested.** It is not Unix work.

### Slice 1 — Make the guardrails guard

`tier_floor: senior` · `complexity: M`

1. **Install the six real binaries on PATH.** `~/.local/bin` symlinks (not a homebrew
   tap — overkill for one user). This alone repairs C2's resolution failure.
   *Verify:* `command -v conductor bursar warden hindsight provenance gauntlet` resolves all six.
2. **conductor: `bursar unavailable` must fail closed.** Today `unavailable` →
   `StaticCaps` → `Info`. It must map to **`SpendCautiously`** — mirroring the existing
   `unknown` arm in `bursar.rs::evaluate_budget` exactly — and render at `Warn`. Do not
   invent a new `BudgetAction`. (Rationale for choosing `unknown`'s arm and not a
   stricter `Defer`: `unknown` means bursar ran and doesn't know; `unavailable` means we
   couldn't even ask. The latter is not *less* uncertain than the former, so it inherits
   the same floor. A stricter posture is a config choice, not a default.)
   **This is the single most important change in the spec.**
   *Verify:* a test asserting `unavailable` does not yield `StaticCaps`; `cargo test`.

   > **Items 1 and 2 must land in the same commit.** Conductor has used `StaticCaps` for
   > this project's entire life, because bursar has never been on PATH. Making
   > `unavailable` fail closed *without* installing bursar would flip every cycle to
   > `SpendCautiously` and change behavior fleet-wide. Installing bursar (item 1) makes
   > item 2 a no-op on the happy path and a real guardrail on the sad one.
3. **bursar: exit non-zero on provider auth/quota failure.** Preserve the documented
   v1 rule that a *complete* status run exits 0; the change is that a live auth failure
   (the 401) is not a complete run.
   *Verify:* `cargo test`; live `bursar status --json; echo $?` against a bad token.
4. **conductor `scan`: exit 0 on ordinary skips, and accept `--config`.** `NotBeadsRepo` /
   `Excluded` are normal, not errors — reserve non-zero for a real `ScanGap`. Add
   `--config <path>`, mirroring every other subcommand, so the suite's one JSON endpoint
   is not cwd-dependent (C6c).
   *Verify:* `conductor scan --json --config ~/git/conductor/conductor.toml` from `/tmp`
   → exit 0, valid JSON on stdout.

4b. **Add `bursar` to `conductor config check`'s preflight** (C6b). It currently checks
   ten external tools and omits the one guild member it shells out to. **This is the
   cheapest change in the spec and the one that would have prevented C2 entirely.**
   *Verify:* with bursar off PATH, `conductor config check` reports it missing and exits non-zero.
5. **warden: fail closed on crash.** Non-zero exit + a deny-shaped JSON object on
   malformed/non-UTF-8 stdin. **Leave allow/ask/deny at exit 0** — that is the correct
   hook contract.
   *Verify:* `printf '\xff' | warden-claude-pretooluse; echo $?` → non-zero, and stdout is a deny verdict.
6. **Fix the `harness-conductor` rename fallout:** guildhall README, `demo/run.sh`, and
   the gauntlet golden task's `origin_path`.
   *Verify:* `gauntlet lint golden-tasks` exits 0 (currently 128).
7. **`gauntlet lint` must be static.** No live `git worktree add/remove` against sibling
   repos on a lint.
   *Verify:* `git -C ~/git/warden status --porcelain` is clean after a lint run.
8. **A regression test on the integration path.** Assert: bursar resolves on PATH;
   bursar exits non-zero on auth failure; conductor's budget path does not silently
   degrade. **The reason nobody caught C2 is that nothing tests this seam.** The test is
   the structural fix; the rest is the symptom.
   *Verify:* the new test fails on the pre-Slice-1 tree and passes after.

### Slice 2 — Make it usable

`tier_floor: junior` · `complexity: S`

9. **`--help` on all six binaries.** A real arm, not the unknown-subcommand fallthrough.
   *Verify:* `<tool> --help; echo $?` → 0 with usage text, for each of the six.
10. **One suite usage guide** (`guildhall/USAGE.md`) — what each member does, the exact
    invocation, what it emits, what it mutates, and its exit-code meanings. **One guide,
    not six READMEs.** This is the artifact the owner actually asked for.
    *Verify:* every command in the guide runs as written, from a clean shell.

### Slice 3 — The one pipe that pays for itself

`tier_floor: lead` · `complexity: L` · charter amendment landed (decisions.md [2026-07-13])

11. **`hindsight events --since <t> --json`** — one normalized `Event` per line on
    stdout. Ship it **together with its first consumer**, never speculatively.
    Requirements, all three from the panel and all mandatory:
    - **SIGPIPE-safe.** Handle `BrokenPipe` as a clean exit, not a panic (C5).
      *Verify:* `hindsight events --since 30d | head -1` exits 0 with no panic.
    - **Redacted.** Transcripts carry shell commands and env dumps. Emitting them to
      stdout is a secret-egress surface (`ps`, audit logs, error dumps see it), and the
      owner's `ai-scratch/` rule is default-deny egress. Redaction posture is a
      precondition, not a follow-up.
    - **Carries `artifact{path,sha256}`** per the envelope rule above.
12. **`gauntlet cost --stdin`** consuming that stream, **retiring `gauntlet/src/cost.rs`'s
    forked pi-log parser** (C3).
    *Verify:* `gauntlet` no longer parses `~/.pi/agent/logs/*` directly (grep is clean);
    `cargo test` green in gauntlet; cost figures match the pre-change baseline.

### Explicit non-goals

Cut deliberately, on the panel's advice:

- **Blanket `--json` on every member.** Add it only where a real consumer exists.
- **A uniform 0/1/2/3 exit taxonomy across all six.** Fix the three broken exit codes;
  leave the rest.
- **Six separate READMEs.** One guide; `.docs/ai/` remains the agent surface.
- **A shared parser crate.** See § The parser question.
- **`hindsight events` as a standalone.** It ships with a consumer or not at all.
- **`provenance`'s view structs.** Not a defect. Do not "fix."

### Slice 1 — AS BUILT (2026-07-13)

Shipped: conductor `08b35b4` (241 tests + 1 integration, clippy clean) · warden `49157c8`
(48 tests, clippy clean) · gauntlet `490655c` (138 tests, clippy clean) · guildhall (docs).
Six binaries symlinked into `~/.local/bin` (source dir is `private_dot_local/bin` — **no
`exact_` prefix**, so chezmoi will not purge them on apply; verified before writing).

**S1.3 WITHDRAWN — it was wrong, and would have shipped a regression.**
The item said "make `bursar status` exit non-zero on auth failure." Tracing conductor's
error handling first (`src/bursar.rs:159`) showed that a non-zero bursar exit makes
conductor treat the run as a **command error and discard the entire report** — including a
perfectly healthy `codex: ok, 100%`. One provider's expired token would have made conductor
cautious about *every* provider.

The category error was mine: **a global exit code cannot express per-provider state.**
`bursar status` is a *report*; exit 0 is correct and the report is honest — the same defense
the panel correctly gave warden, which I then failed to apply to bursar. Conductor already
maps `ProviderState::Error` → `SpendCautiously` (`bursar.rs:231-240`), so the 401 was
*already* handled. What is missing is a **predicate** — `bursar check <provider>` — which is
an addition, not a bug fix. **Moved to Slice 2.**

**C6c partially wrong.** `conductor scan` *does* accept `--config`; only the `USAGE` string
omitted it, so the flag was undiscoverable. The cwd-dependence I observed was me not passing
a flag I didn't know existed. Fixed the doc string; no parsing change needed.

**C7 ran deeper than the audit found.** Beyond the README, demo, and golden task: gauntlet's
`gauntlet.toml` `[sandbox] read_only_refs` and a golden task's own `prompt` field carried the
dead path (a worker agent found both); the guildhall runbook still told agents to load the
worker-prompt template from the dead path; and `tests/worker_prompt.rs` failed on a
**stale build artifact** — `env!("CARGO_MANIFEST_DIR")` is baked in at compile time, so a
binary compiled before the rename carried the old path. Not a source bug; a rebuild fixes it.

**NEW, and it needs a human**: conductor's `[[repo_policy]]` table — the control deciding
which repos a *free-train* model may see — is **uncommitted** in the working tree, while the
*committed* test asserts `repo_policies.len() == 11`. Conductor's suite therefore passes only
because of an uncommitted file; a fresh clone goes red, and the security policy itself is not
in version control. Left untouched (not this session's work, and security-relevant).

**Conductor has its own newer ADR.** `conductor/.docs/ai/decisions.md` `[2026-07-13]`
("Provider state is fail-closed at plan and dispatch") + `phases/provider-trust-integration-spec.md`
already approve a v2 where `unknown`/`unavailable` both map to `Defer` — stricter than the
`SpendCautiously` shipped here. Not a collision: both are fail-closed, and this is a
compatible interim hardening of the v1 model. Whoever picks up that spec will move this arm
to `Defer`; that is expected, not a regression.

### Findings routed but not fixed here

Every finding above is routed. These are the ones this spec deliberately does **not**
close — recorded so they are not silently dropped, and filed as beads instead:

| finding | disposition |
|---|---|
| C6 — `provenance query` exits 0 on findings **and on blindness** | **Bead, P2** (raised from P3 on live evidence). Provenance's *prose* is exemplary — it reports `uncorrelated hunks: 147` rather than claiming "all clear," which is charter invariant 8 working as written. But it **exits 0 regardless**, so `provenance query && merge` passes on "I could not evaluate 147 hunks" exactly as readily as on "it's clean." Fix the exit code, not the output: a distinct non-zero for *flagged*, and another for *could-not-evaluate*. Do NOT "fix" the prose — it is the model the rest of the suite should copy. |
| C8 — `hindsight recap` writes a report dir every run | **Bead, P2.** Arguably the persisted report *is* recap's product; the defect is the absence of `--no-write`, not the write. Add the flag; don't change the default. |
| C8 — `conductor cycle --dry-run` writes a report | **Accepted.** The report *is* the dry-run's deliverable. The name is misleading; the behavior is right. No change. |
| C8 — `conductor arena run` auto-applies the winner | **Bead, P2 — and a real footgun.** Applying a model's patch to a live repo by default inverts the fail-closed invariant. Should default to `--no-apply`. Out of this spec's scope (it touches the Arena path, not the budget path), but it should not wait long. |
| C9 — `--help` for envoy's bash validator | **Accepted.** Envoy is not one of the six binaries. |

## Risks

- **Slice 1 touches the budget path while the autonomy ladder is mid-flight.** Land it
  behind the existing tests; `conductor` has 238 of them.
- **Installing bursar means conductor will start actually calling it.** `use_bursar` has
  defaulted to `true` this whole time, but the call has always failed to resolve. Once
  bursar is on PATH, every cycle does a live network call to the Anthropic OAuth usage
  endpoint plus a macOS Keychain read — bursar has no cache and no `--offline`. Expect a
  one-time Keychain prompt and added per-cycle latency. If that latency bites, the fix is
  a bursar cache, not reverting item 2. **Do not discover this in production**: run one
  `conductor cycle --dry-run` immediately after Slice 1 lands and watch what happens.
- **Redaction is unscoped.** If Slice 3's redaction posture proves large, `hindsight
  events` may need a `--redact` default with an explicit opt-out rather than a full
  classifier. Escalate rather than shipping raw transcripts to stdout.
- **The panel's minimax lane argued the whole target is wrong** (agents want MCP tool
  calls, not pipes). Rejected: the agents in this fleet are shell-first — Claude Code,
  Codex, pi, and opencode all reach these tools through a Bash tool, and `bd ready
  --json | jq` is the existing idiom. Recorded because if the fleet ever moves to
  MCP-native members, this decision should be revisited.

## What the panel changed

Recorded because the deltas are the value:

- **Killed the composite scores** (unanimous) — they implied interval semantics that
  ordinal judgments do not support, and would have mis-prioritized the work.
- **Killed the uniform rubric** (glm) — replaced with role-keyed axes. The headline
  finding of the first draft ("stdin is 0 everywhere") was an artifact of the grid.
- **Rescued provenance** (glm) — its structs are correct decoupling, wrongly flagged.
- **Split warden's exit code** (glm) — exit-0-on-verdict is right; exit-0-on-crash is a bug.
- **Re-ordered the plan** (glm) — safety first, alone; the emitter ships with its consumer.
- **Sharpened C2** (qwen) — challenged an unverified "silently," and the re-check found
  something worse: missing renders `Info` while uncertain renders `Warn`.
- **Found SIGPIPE and secret-egress in the proposal itself** (minimax) — both since
  verified.
- **The artifact-identity envelope** (qwen + minimax, convergent) — the rule that keeps
  "artifacts are evidence" alive once a pipe exists.
