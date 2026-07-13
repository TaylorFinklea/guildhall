# Guildhall — operator's guide

**Every command here was run on 2026-07-13 and does what it says.** Where a tool
misbehaves, that is recorded rather than hidden.

## Read this first

**All six binaries are on `PATH`** (symlinked into `~/.local/bin`, which chezmoi manages
without `exact_`, so they survive `chezmoi apply`). The symlinks point at
`target/release/`, so a `cargo build --release` refreshes them in place — but a
`cargo clean` leaves them dangling.

Rebuild all six (idempotent, ~1 min cold):

```sh
for m in conductor bursar warden hindsight provenance gauntlet; do
  cargo build --release --manifest-path "$HOME/git/$m/Cargo.toml"
done
```

One name is not what you'd guess: **warden's binary is `warden-claude-pretooluse`**, not
`warden`.

**There is no `--help` yet.** Run a tool with **no arguments** to get its usage string —
that is the discovery mechanism today. (Slice 2 fixes this.)

## The suite in one breath

Eight *members*, but only **six are binaries**. Conductor runs the loop; the other five
answer one question each.

| member | the one question it answers |
|---|---|
| **conductor** | "What work is ready, who should do it, and can we afford it?" |
| **bursar** | "Can we afford it?" |
| **warden** | "Should this tool call be allowed?" |
| **hindsight** | "What did the fleet do in the last N hours?" |
| **provenance** | "Which model wrote this line, and was it ever reviewed?" |
| **gauntlet** | "Which model is actually better, on evidence?" |
| envoy | *(not a binary — a skill + a bash envelope validator)* |
| foreman | *(not a binary — spec only, deferred to 2026-08)* |

---

## conductor — the master of works

Scans every repo under `~/git`, triages each one's ready beads by `tier_floor` /
`complexity`, routes each to a roster model, and publishes one plan.

```sh
CFG=~/git/conductor/conductor.toml

conductor config check --config $CFG    # preflight: are my backends installed?
conductor cycle --dry-run --config $CFG # scan → triage → plan. Writes a report.
conductor status                        # summary of the last cycle
conductor roster drift --config $CFG    # scorecard vs conductor.toml
conductor scan --json --config $CFG | jq '.[] | select(.is_beads_repo) | .name'
```

A real dry-run over your fleet today: **42 repos scanned · 190 ready items · 83 triaged ·
159 proposed · 31 flagged UNTRIAGED** (missing `tier_floor`/`complexity` — mostly
patchstand and simmersmith beads).

⚠️ **`arena run` applies the winning patch to your repo by default.** Pass `--no-apply`.
(Filed as a P2 bead — a fail-closed suite should not auto-apply.)

⚠️ **`cycle --dry-run` writes a report file** despite the name. That's arguably the point
— the report *is* the dry-run's product — but it is not side-effect-free.

---

## bursar — the treasury

Answers "can we afford this dispatch?" per provider. Conductor consults it before
spending money.

```sh
bursar status --json | jq -r '.providers | to_entries[] | "\(.key): \(.value.status)"'
```

Real output today (`bursar/status@1`): `codex: ok` (100%, resets 2026-07-19) ·
`opencode-go: unknown` · `agy: unknown` · `anthropic: **error**`.

⚠️ **Your Anthropic OAuth token is expired.** bursar reports
`HTTP 401: Invalid bearer token` for that lane. It is blind until you re-auth.

**`bursar status` exits 0 even carrying that 401 — and that is CORRECT.** `status` is a
*report*, not a predicate: the run succeeded, and the report honestly says the provider
errored. Conductor reads the JSON and maps `error` → *spend cautiously*, which is exactly
right. A global exit code cannot express per-provider state, and making `status` exit
non-zero would make conductor discard the whole report — losing the good `codex: ok` data
because a *different* provider's token expired.

What's missing is a **predicate**, not a different exit code: `bursar check <provider>`
for shell gating (`bursar check codex && dispatch`). That's Slice 2. **Until then, parse
the JSON — never gate on `$?`.**

Every call does a live network request **and a macOS Keychain read**. No cache, no
`--offline`. Don't put it in a loop.

---

## warden — the inspecting officer

A **proper Unix filter**, and the best-behaved tool in the suite. A Claude Code
`PreToolUse` event on stdin, an allow/ask/deny verdict as JSON on stdout. Nothing else.

```sh
printf '{"session_id":"s","transcript_path":"/tmp/t","cwd":"'$PWD'","hook_event_name":"PreToolUse","permission_mode":"ask","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | warden-claude-pretooluse | jq -r '.hookSpecificOutput.permissionDecisionReason'
# → warden: Claude Bash -> BashCeiling; hard-ceiling: BashCeiling
```

The fail-closed invariant is real — an unrecognized tool is gated, not passed:

```
warden: Claude SomeUnknownTool -> Unknown; ungated category: Unknown (fail-closed)
```

**Exit codes**: `0` on a genuine verdict (allow/ask/deny) — correct, because Claude Code
reads the decision from stdout JSON, not from `$?`. **Non-zero on a crash**, with a *deny*
verdict still on stdout, so a caller can never mistake a crash for an allow:

```sh
printf '\xff\xfe' | warden-claude-pretooluse; echo "exit=$?"
# → {"hookSpecificOutput":{...,"permissionDecision":"deny","permissionDecisionReason":"warden adapter failed closed: ..."}}
# → exit=1
```

⚠️ **It is not installed as a hook yet.** It's a binary you can pipe to, not a live gate.

---

## hindsight — the flight recorder

Parses the fleet's transcript substrate (Claude Code, Codex, pi, agy, guardian JSONL) and
tells you what happened in a window.

```sh
hindsight recap --since 24h    # 🚫 not run here — see below
```

⚠️ **`recap` writes a new report directory every single time you run it** —
`~/.harness/reports/hindsight/recap-<ts>/` — with no `--no-write`. Run it three times, get
three directories. A read command with a permanent side effect. (Filed as a P2 bead.)

**It cannot emit the event stream.** `recap` builds the normalized `Vec<Event>`, folds it
into summary tallies, and discards it. There is no `hindsight events`. This is the
suite's most consequential gap — see provenance.

---

## provenance — the hallmarks

Correlates agent transcripts against git hunks: *which model wrote this line, and was it
ever reviewed by an equal-or-higher tier?*

```sh
provenance annotate ~/git/guildhall
provenance query unreviewed-junior ~/git/guildhall
```

Real output on this repo: `annotations: 147` · `uncorrelated commits: 38`.

**Guildhall has exactly 38 commits. All 38 are uncorrelated.** Provenance works — and
correlates *nothing*, because it has no event source. It is still on `FixtureEventSource`,
waiting on a stream that hindsight builds and throws away. **A working engine with no fuel
line.** That is what Slice 3 connects.

**Credit where it's due: provenance is the most honest tool here.** `query` does not claim
"all clear" — it reports its own blindness:

```
FLAGGED HUNKS (Junior-tier, no later Senior+ touch to the same file)
(no flagged hunks)

EXCLUDED FROM RESULT SET (per Invariants 2 and 9)
uncorrelated hunks:  147
```

That's charter invariant 8 ("coverage gaps are reported as gaps") working as written.
⚠️ Its one defect is narrow: it **exits 0** regardless — so `provenance query && merge`
passes on "I'm blind" exactly as readily as on "it's clean." **Read the output, not `$?`.**

The sidecar is plain JSONL under `~/.local/state/`, never inside the annotated repo — so
`jq` it directly if you want the data today.

---

## gauntlet — the masterpiece trials

Replays golden tasks in throwaway git worktrees against different models, runs each
task's Verify, judges fail-closed, and produces the evidence behind the roster ratings.

```sh
cd ~/git/gauntlet
gauntlet list golden-tasks     # id + title, TSV
gauntlet lint golden-tasks     # static; exit 0, defective=0
gauntlet config check
gauntlet run --dry-run         # no metered dispatch
```

**`lint` is now static** — it validates structure and resolves `base_commit` read-only
(`git cat-file -e`), and never creates a worktree in your live repos. It also prints, on
every run, exactly what it *no longer* checks:

> *"lint: static checks only… cannot confirm a task's gate discriminates a working fix
> from a no-op at base_commit; that check now requires `gauntlet validate --smoke-run`."*

That discrimination check moved to **`validate --smoke-run`**, which *does* create a real
worktree — deliberately, and only when you ask for it.

🛑 **`gauntlet run` without `--dry-run` dispatches real, metered models. It costs money.**

---

## envoy — the emissary *(no binary)*

A skill (markdown an agent reads) plus a bash envelope validator. No `envoy` command, no
live transport — the agent-bus it was meant to ride is broken end-to-end.

```sh
bash ~/git/envoy/scripts/validate-envelope.sh ~/git/envoy/fixtures/golden-answer.json
# → OK: ... conforms to guildhall/envoy@1        (exit 0)
```

It fails closed correctly: the broken fixture reports *"both .answer.evidence and
.answer.gaps are empty — fail-closed evidence-or-gaps disjunction violated"*, exit 1.

The skill is **not installed** to `~/.claude/skills/`.

## foreman — the works office *(nothing exists)*

Spec only. No `Cargo.toml`, no source. All six beads deferred to 2026-08 by ADR. Lead
sessions do this job by hand. Not a defect — roadmap.

---

## The glue

Also on `PATH`, and genuinely composable:

```sh
bd -C ~/git/conductor ready --json | jq -r '.[0].id'    # → conductor-xa5
harness-deck contract                                   # the full report schema
hdeck validate report.json                              # exit 0/1/2 — a real CI gate
ralph -t opencode -n 5                                  # headless Plan-item loop
```

`bd ready --json | jq` is the cleanest pipe in the fleet. It's the model to copy.

## Landmines — the short list

| # | landmine | status |
|---|---|---|
| 1 | `hindsight recap` writes a report dir on **every** run | open (P2) |
| 2 | `conductor arena run` **auto-applies** the winner — use `--no-apply` | open (P2) |
| 3 | `provenance query` exits **0** whether it's clean *or blind*. Read the output. | open (P2) |
| 4 | `bursar` has no predicate — parse the JSON, never gate on `$?` | Slice 2 |
| 5 | No `--help` anywhere. Run a tool bare to get its usage. | Slice 2 |
| 6 | `gauntlet run` without `--dry-run` **spends real money** | by design |
| 7 | **conductor's `[[repo_policy]]` table is UNCOMMITTED.** It decides which repos a free-train model may see, and conductor's own test asserts 11 rows — so the suite passes *only* because of an uncommitted file. A fresh clone goes red. | **needs a human decision** |
| ~~8~~ | ~~Nothing on PATH~~ · ~~budget gate fails open~~ · ~~`config check` skips bursar~~ · ~~`scan` exits 1 when healthy~~ · ~~`gauntlet lint` exits 128 and mutates live repos~~ · ~~warden exits 0 on crash~~ | **FIXED, Slice 1** |

## What "fixed" looks like next

`.docs/ai/phases/unix-composability-spec.md`. Slice 2 gives every binary a `--help`, adds
`bursar check <provider>`, and keeps this guide honest. Slice 3 builds `hindsight events`
and finally gives provenance its fuel line.
