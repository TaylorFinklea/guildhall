# Guildhall — operator's guide

**Every command in this file was run on 2026-07-13**, with **two deliberate exceptions**,
marked 🚫 below: `hindsight recap` (writes a report directory on every run) and
`gauntlet lint` (mutates live sibling repos). Their behavior is attested by a recon agent
that ran them, not by me. Everything else is first-hand. Where a tool misbehaves, that is
recorded rather than hidden.

## Read this first

**Nothing is on `PATH`.** Not conductor, not bursar, not hindsight, not gauntlet. Only
`harness-deck`, `bd`, and `ralph` resolve by name. Every guild command below is therefore
an absolute path. `phases/unix-composability-spec.md` Slice 1 fixes this; until it lands,
this is the truth.

Build all six binaries (idempotent, ~1 min cold):

```sh
for m in conductor bursar warden hindsight provenance gauntlet; do
  cargo build --release --manifest-path "$HOME/git/$m/Cargo.toml"
done
```

Two names are not what you'd guess:
- **warden's binary is `warden-claude-pretooluse`**, not `warden`.
- **conductor's config is `~/git/conductor/conductor.toml`**. Anything pointing at
  `~/git/harness-conductor/` is stale — that directory no longer exists, and the
  `demo/run.sh` command that references it 404s.

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

Scans every repo in `~/git`, triages each one's ready beads by `tier_floor`/`complexity`,
routes each to a roster model, and publishes one plan. This is the orchestrator; the
others are its instruments.

```sh
C=~/git/conductor/target/release/conductor
CFG=~/git/conductor/conductor.toml

$C config check --config $CFG      # preflight: are my backends installed?   exit 0 ✓
$C cycle --dry-run --config $CFG   # scan → triage → plan. Writes a report.
$C status                          # summary of the last cycle
$C roster drift --config $CFG      # scorecard vs conductor.toml
$C scan --json                     # ⚠ see below — cwd-dependent, exit code lies
```

**`scan` is the odd one out.** It is the only subcommand with `--json`, and the only one
*without* `--config` — so it reads `conductor.toml` from your **current directory**. Run
it from anywhere else and you get `exit 2: failed to read conductor.toml`. Run it from
`~/git/conductor` and it works:

```sh
cd ~/git/conductor && ./target/release/conductor scan --json | jq '.[] | select(.is_beads_repo)'
```

…but it **exits 1 on a completely healthy scan**, because ordinary `NotBeadsRepo` skips
(every non-beads repo in `~/git`) are counted as failures. The JSON is clean, stderr is
empty, and the exit code is a lie. `conductor scan --json | jq` works. `conductor scan &&
echo ok` never prints `ok`.

⚠️ **`arena run` applies the winning patch to your repo by default.** Pass `--no-apply`.

⚠️ **`cycle --dry-run` writes a report file** despite the name. That's arguably the point
— the report *is* the dry-run's output — but it is not side-effect-free.

---

## bursar — the treasury

Answers "can we afford this dispatch?" for each provider. Conductor consults it before
spending money.

```sh
~/git/bursar/target/release/bursar status --json | jq '.providers | to_entries[] | "\(.key): \(.value.status)"'
```

Real output today (`bursar/status@1`): `codex: ok` (100%, resets 2026-07-19) ·
`opencode-go: unknown` · `agy: unknown` · `anthropic: **error**`.

⚠️ **Two things to know.**

1. **Your Anthropic OAuth token is expired.** bursar reports
   `HTTP 401: Invalid bearer token` for the anthropic lane right now. That lane is blind.
2. **`bursar status` exits 0 anyway** — even carrying that live 401. So
   `bursar status && dispatch` always dispatches. There is no exit-code predicate; you
   must parse the JSON. (Slice 1 fixes this.)

Every call does a live network request **and a macOS Keychain read**. No cache, no
`--offline`. Don't put it in a loop.

---

## warden — the inspecting officer

A **proper Unix filter** — the best-behaved tool in the suite. A Claude Code `PreToolUse`
event on stdin, an allow/ask/deny verdict as JSON on stdout. Nothing else.

```sh
W=~/git/warden/target/release/warden-claude-pretooluse

printf '{"session_id":"s","transcript_path":"/tmp/t","cwd":"'$PWD'","hook_event_name":"PreToolUse","permission_mode":"ask","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | $W | jq -r '.hookSpecificOutput.permissionDecisionReason'
# → warden: Claude Bash -> BashCeiling; hard-ceiling: BashCeiling
```

The fail-closed invariant is real — an unrecognized tool name is gated, not passed:

```
warden: Claude SomeUnknownTool -> Unknown; ungated category: Unknown (fail-closed)
```

It always exits 0. **That is correct** — Claude Code reads the decision from the stdout
JSON, not from `$?`. (It also exits 0 on a *crash*, which is not correct; Slice 1 fixes
that arm only.)

**It is not installed as a hook yet.** It is a binary you can pipe to, not a live gate.

---

## hindsight — the flight recorder

Parses the fleet's transcript substrate (Claude Code, Codex, pi, agy, guardian JSONL) and
tells you what happened in a window.

```sh
~/git/hindsight/target/release/hindsight recap --since 24h    # 🚫 not run here — it writes
```

⚠️ **`recap` writes a new report directory every single time you run it** —
`~/.harness/reports/hindsight/recap-<ts>/` — with no `--no-write`. Run it three times, get
three directories. It is a read command with a permanent side effect.

**It cannot emit the event stream.** `recap` builds the normalized `Vec<Event>` internally,
folds it into summary tallies, and discards it. There is no `hindsight events`. This is
the single most consequential gap in the suite — see provenance.

---

## provenance — the hallmarks

Correlates agent transcripts against git hunks: *which model wrote this line, and was it
ever reviewed by an equal-or-higher tier?*

```sh
P=~/git/provenance/target/release/provenance
$P annotate ~/git/guildhall              # writes a sidecar; prints a summary
$P query unreviewed-junior ~/git/guildhall
```

Real output on this repo:

```
annotations: 147
uncorrelated commits: 38
sidecar: ~/.local/state/provenance/-Users-tfinklea-git-guildhall/annotations.jsonl
```

**Guildhall has exactly 38 commits. All 38 are uncorrelated.** Provenance works — and it
correlates *nothing*, because it has no event source. It is still on `FixtureEventSource`,
waiting on a live stream that hindsight builds and throws away. **A working engine with no
fuel line.** That is what Slice 3 connects.

**Credit where it's due: provenance is the most honest tool in the suite.** `query` does
not claim "all clear" — it reports its own blindness:

```
FLAGGED HUNKS (Junior-tier, no later Senior+ touch to the same file)
(no flagged hunks)

EXCLUDED FROM RESULT SET (per Invariants 2 and 9)
unknown-tier hunks:  0
uncorrelated hunks:  147
```

That is charter invariant 8 ("coverage gaps are reported as gaps") working as written.
⚠️ Its one defect is narrow: it **exits 0** regardless — so `provenance query && merge`
passes on "I'm blind" exactly as readily as on "it's clean." Read the output, not `$?`.

The sidecar is plain JSONL under `~/.local/state/`, never inside the annotated repo — so
`jq` it directly if you want the data today.

---

## gauntlet — the masterpiece trials

Replays golden tasks in throwaway git worktrees against different models, runs each task's
Verify, judges fail-closed, and produces the evidence behind the roster's ratings.

```sh
cd ~/git/gauntlet
./target/release/gauntlet list golden-tasks       # id + title, TSV
./target/release/gauntlet lint golden-tasks       # ⚠ currently exit 128 — see below
./target/release/gauntlet config check
./target/release/gauntlet run --dry-run           # no metered dispatch
```

⚠️ **`gauntlet lint` is broken right now.** One golden task's `origin_path` still points at
the deleted `~/git/harness-conductor`, so lint exits **128**. Slice 1 fixes it.

⚠️ **`lint` and `validate --smoke-run` do live `git worktree add/remove` against your real
sibling repos.** A lint should be static. Check `git status` in warden/hindsight/provenance
afterwards until Slice 1 lands.

🛑 **`gauntlet run` without `--dry-run` dispatches real, metered models.** It costs money.

---

## envoy — the emissary *(no binary)*

A skill (markdown an agent reads) plus a bash envelope validator. There is no `envoy`
command and no live transport — the agent-bus it was meant to ride is broken end-to-end.

```sh
bash ~/git/envoy/scripts/validate-envelope.sh ~/git/envoy/fixtures/<envelope>.json
```

Exit 0 = conforms, 1 = violates. The skill is **not installed** to `~/.claude/skills/`.

## foreman — the works office *(nothing exists)*

Spec only. No `Cargo.toml`, no source. All six beads deferred to 2026-08 by ADR. Lead
sessions do this job by hand. Not a defect — roadmap.

---

## The glue that already works

These three *are* on `PATH` and are genuinely composable today:

```sh
bd -C ~/git/conductor ready --json | jq -r '.[0].id'    # → conductor-xa5
harness-deck contract                                   # the full report schema
hdeck validate report.json                              # exit 0/1/2 — a real CI gate
ralph -t opencode -n 5                                  # headless Plan-item loop
```

`bd ready --json | jq` is the one clean pipe in the whole fleet. It's the model everything
else should follow.

## Landmines — the short list

| # | landmine |
|---|---|
| 1 | **Nothing is on PATH.** Absolute paths everywhere. |
| 2 | **conductor's budget gate fails open.** bursar isn't on PATH → `Command::new("bursar")` fails → conductor silently uses static caps and renders it as `Info`. Your spend guardrail is off. |
| 3 | `conductor config check` passes — **but it never checks bursar.** That's why nobody caught #2. |
| 4 | `bursar status` exits **0** on a live 401. Never gate on `$?`. |
| 5 | `conductor scan` exits **1** on a healthy scan, and has no `--config`. |
| 6 | `hindsight recap` writes a report dir on **every** run. |
| 7 | `gauntlet lint` exits **128** (stale golden task) and mutates live repos. |
| 8 | `conductor arena run` **auto-applies** the winner. Use `--no-apply`. |
| 9 | `gauntlet run` without `--dry-run` **spends real money.** |
| 10 | No member has `--help`. `<tool> --help` = "unknown subcommand", exit 1 or 2. Run a tool with **no arguments** to get its usage string — that's the discovery mechanism today. |

## What "fixed" looks like

`phases/unix-composability-spec.md`. Slice 1 closes landmines 1–5 and 7. Slice 2 gives
every binary a `--help` and keeps this guide honest. Slice 3 builds `hindsight events` and
finally gives provenance its fuel line.
