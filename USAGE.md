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

**Every binary has `--help` now** (exit 0, usage on stdout). Start there.

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

**The predicate — this is what you gate on:**

```sh
bursar check codex && echo "safe to dispatch"
```

`bursar check <provider>` → **0** affordable · **1** exhausted · **2** usage error · **3**
**cannot determine**. It **fails closed**: `unknown` and `error` both exit 3, so
`bursar check anthropic && spend` will *not* spend while that lane is blind. Live today:
`codex`→0 · `anthropic`→3 · `opencode-go`→3 (vendor-opaque) · `nonesuch`→2.

`--threshold <pct>` (default 90, matching conductor) gates earlier if you want.
**`percent` means utilization — percent *used*, not remaining.**

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
hindsight recap  --since 24h                  # a summary. ⚠️ writes a report dir.
hindsight events --since 24h                  # the EVENT STREAM — one JSON Event per line
```

**`hindsight events` is the `cat` of the suite** — the normalized stream every other
member reads. ~170,000 events over 7 days. It is a proper filter: SIGPIPE-safe (`| head`
works), quiet, no side effects, and each event carries `raw_ref{path,line}` pointing back
at the exact transcript record it came from — **the stream is a view; the record is the
evidence.**

```sh
hindsight events --since 7d | jq -r 'select(.kind=="commit_evidence") | .agent.model' | sort | uniq -c
```

🔒 **It redacts by risk, not blanket.** `tool.input_summary` is **cleared on every event
kind except `commit_evidence`** — because for a Bash call that field holds the raw shell
command, which may carry a credential. A commit message is already in `git log`, so
emitting it discloses nothing new. Verified: across a 7-day, 175k-event stream, the only
non-`commit_evidence` `input_summary` value is the empty string. `--unsafe-include-tool-input`
opts in and warns on stderr.

⚠️ **`recap` writes a new report directory every single time you run it** —
`~/.harness/reports/hindsight/recap-<ts>/` — with no `--no-write`. `events` does not.

---

## provenance — the hallmarks

Correlates agent transcripts against git hunks: *which model wrote this line, and was it
ever reviewed by an equal-or-higher tier?*

**The fuel line — this is the money shot:**

```sh
hindsight events --since 30d | provenance annotate ~/git/guildhall --events -
provenance query unreviewed-junior ~/git/guildhall
```

Then ask who wrote what:

```sh
jq -r 'select(.model != "") | "\(.commit[0:7])  \(.model)  \(.tier)  \(.file)"' \
  ~/.local/state/provenance/-Users-tfinklea-git-guildhall/annotations.jsonl | sort -u
# 19990ea  claude-opus-4-8  lead  .docs/ai/phases/unix-composability-spec.md
# 19990ea  claude-opus-4-8  lead  README.md
```

**It was 43 of 43 commits uncorrelated — 100% blind. It is now 37.** Provenance had no
event source and was stuck on a `FixtureEventSource`; `hindsight events` is the stream it
was always waiting for. It correlates by commit **message + cwd + window** (hash
correlation can't fire yet — live events don't carry `repo.git_commit`; bead
`hindsight-w5w`).

📊 **The honest gap**: all 37 still-uncorrelated commits **predate `2026-07-12T02:41Z`** —
the earliest record in hindsight's transcript retention. That is a *retention* limit, not a
join defect, and provenance says so rather than hiding it.

**Provenance is the most honest tool here.** `query` does not claim "all clear" — it
reports its own blindness:

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

**It no longer forks hindsight's parser.** `gauntlet cost` now reads the normalized event
stream on stdin — one parser, one ground truth, over a pipe:

```sh
hindsight events --since 7d | gauntlet cost --stdin --model glm-5.2 \
  --cwd ~/git/tesela --started 2026-07-12T04:30:00Z --finished 2026-07-12T04:40:00Z
# cost	$0.2441
```

🔒 **`cost: 0` still means UNKNOWN, not free.** Some lanes report zero cost for every
record; treating that as `$0.00` would make the roster's efficiency ratings fiction.
Gauntlet fails closed to `unknown` — verified to survive the de-fork.
**hindsight reports facts; gauntlet judges them.**

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
| 1 | **A `cargo test` (debug) does NOT update the `~/.local/bin` symlinks — they point at `target/release/`. Rebuild `--release` before trusting a PATH binary.** This bit three times in one session. | inherent |
| 2 | `hindsight recap` writes a report dir on **every** run (`events` does not) | open (P2) |
| 3 | `conductor arena run` **auto-applies** the winner — use `--no-apply` | open (P2) |
| 4 | `provenance query` exits **0** whether it's clean *or blind*. Read the output. | open (P2) |
| 5 | `gauntlet run` without `--dry-run` **spends real money** | by design |
| 6 | Provenance can only see back to **2026-07-12** — hindsight's transcript retention. Older commits are honestly reported as uncorrelated, not as clean. | inherent |
| 7 | **Don't run two agent sessions against the same repo.** Charter invariant 5. A concurrent session `git reset` away a commit during this work; it was only recovered from the reflog because an agent noticed. | **process** |
| ~~8~~ | ~~Nothing on PATH~~ · ~~budget gate fails open~~ · ~~`config check` skips bursar~~ · ~~`scan` exits 1 when healthy~~ · ~~`gauntlet lint` exits 128 + mutates~~ · ~~warden exits 0 on crash~~ · ~~`[[repo_policy]]` uncommitted~~ · ~~no `--help` anywhere~~ · ~~no `bursar` predicate~~ · ~~no event stream~~ · ~~gauntlet forked the parser~~ · ~~provenance blind~~ | **FIXED** |

## The suite, composed

Everything below is one shell line. That was the point.

```sh
bursar check codex && conductor cycle --dry-run --config ~/git/conductor/conductor.toml

hindsight events --since 30d | provenance annotate ~/git/guildhall --events -

hindsight events --since 7d | gauntlet cost --stdin --model glm-5.2 --cwd ~/git/tesela \
  --started 2026-07-12T04:30:00Z --finished 2026-07-12T04:40:00Z

hindsight events --since 24h | jq -r 'select(.kind=="commit_evidence") | .agent.model' \
  | sort | uniq -c | sort -rn
```
