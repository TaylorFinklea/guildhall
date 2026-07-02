# Guildhall shared ingestion event model — v1

**Status**: charter spec (2026-07-01), recon-grounded. **First implementation
lives in hindsight** (`~/git/hindsight`); extracted to a shared lib only when
provenance needs it. Do not fork parsers.

## Sources (all verified on disk 2026-07-01; sample before trusting shapes)

| source id | path glob | format | identity fields | git correlation | notes |
|---|---|---|---|---|---|
| `claude-code` | `~/.claude/projects/<slug>/<sessionId>.jsonl` | JSONL, typed records (`assistant`,`user`,`system`,…) | `message.model`, `sessionId`, `version` | **`cwd` + `gitBranch` on EVERY record**; commit msg + `Co-Authored-By` inside Bash `tool_use.input.command` | slug = cwd with `/`→`-`. Subagents: `<sessionId>/subagents/agent-<hash>.jsonl` + `.meta.json` (`toolUseId` joins to parent `tool_use.id`). Big outputs in `<sessionId>/tool-results/`. Filter non-transcript noise (`memory/`, `bridge-pointer.json`). 1.9 GB / 5,854 files, unbounded retention. |
| `pi-session` | `~/.pi/agent/sessions/<slug>/<ts>_<id>.jsonl` | JSONL (`session`,`message`,`model_change`,…) | `provider`, `model`, per-msg `usage`+`cost` | **none** — infer from bash `toolCall.arguments.command` strings | slug wrapped in double dashes. Many are ephemeral `harness-*` test runs — filter. |
| `pi-observability` | `~/.pi/agent/logs/session-<id>.jsonl` | JSONL events (`session_start`,`provider_request/response`,`tool_call`,`tool_result`,`assistant_message`,`agent_end`) | model/provider per event | via joined session file | `session_start.sessionFile` → exact join to `pi-session`. `provider_response.headers` carries OpenAI rate-limit headers (populated for openai-codex, EMPTY for opencode-go) — bursar feed. `PI_OBSERVABILITY_DIR` overrides dir. |
| `guardian` | same files as `pi-observability`, `event:"guardian_decision"` | JSONL | mode, category, decision, outcome | `target` (path/command, 200-char cap) | policy audit trail; schema in warden spec. |
| `codex` | `~/.codex/sessions/YYYY/MM/DD/rollout-<ts>-<uuid>.jsonl` | JSONL `{timestamp,type,payload}` | `turn_context.payload.model`; `session_meta.payload.{originator,thread_source}` | **strongest**: `session_meta.payload.git.{commit_hash,branch,repository_url}` + `function_call` `workdir`/`cmd` | `token_count.rate_limits` events = bursar feed. Filter `thread_source:"subagent"` guardian-judge threads (tag, don't drop silently). `~/.codex/logs_2.sqlite` (397 MB) unexplored — flagged, not parsed in v1. |
| `agy` | `~/.gemini/antigravity-cli/log/cli-<ts>.log` | glog text (not JSONL) | model in print-mode start line | none — conversation SQLite under `conversations/` | one file per invocation. `RESOURCE_EXHAUSTED` grep = the no-op detector (exit 0 lies). v1: lifecycle + quota events only, no deep parse. |
| `harness-deck` | `~/.harness/reports/<project>/<run>/report.json` (+`responses.json`) | JSON | `harness`, `agent` | `project` = repo basename | curated summaries; high-signal correlation anchor + destination. |
| `beads` | `<repo>/.beads/interactions.jsonl` | JSONL `field_change` records | `actor` | free-text `reason` often names commit/model — string-match only | issue DB itself is Dolt-embedded (opaque without `bd`); use `bd --readonly ... --json` when full state needed. |
| `model-bench` | `~/.claude/model-bench.jsonl` | JSONL | model, role, project | none | human-curated quality ledger — secondary signal, never primary. |

## Normalized event (v1)

One flat record per interesting moment; `raw_ref` always points home. Sparse —
absent fields are absent, never invented.

```json
{
  "ts": "RFC3339",
  "source": "claude-code|pi-session|pi-observability|guardian|codex|agy|harness-deck|beads",
  "kind": "session_start|message|tool_call|tool_result|commit_evidence|decision|usage|quota|report|field_change",
  "session_id": "…", "parent_ref": "…",
  "agent": {"model": "…", "provider": "…", "harness": "…", "tier": "…?"},
  "repo": {"cwd": "…", "git_branch": "…?", "git_commit": "…?"},
  "tool": {"name": "…", "input_summary": "≤200 chars"},
  "usage": {"input_tokens": 0, "output_tokens": 0, "cost_usd": "…?"},
  "raw_ref": {"path": "…", "line": 0}
}
```

`commit_evidence` is the load-bearing kind for provenance: emitted when a
transcript record shows a `git commit` execution — carries the message
substring, any captured short hash, cwd, ts, and the acting model.

## Correlation keys (recon-verified)

- transcript ↔ commit: `(cwd, ts-window, message-substring)`; Codex adds
  session-start `commit_hash` baseline; Claude Code adds `Co-Authored-By`
  trailer + chained `git log` stdout when present.
- pi-session ↔ pi-observability: `session_start.sessionFile` (exact).
- Claude parent ↔ subagent: `meta.json.toolUseId` = parent `tool_use.id`.
- anything ↔ harness-deck: `(project=repo-basename, ts-window, agent)`.
- cross-harness "what ran at time T in repo R": all sources are UTC
  ISO8601-or-epoch at record level — time-window join is mechanically sound.

## Coverage gaps ledger (report these AS gaps in every recap)

1. **ralph**: zero durable logs (full source read) — iterations reconstructable
   only via backend transcripts + git. Fix = chezmoi-territory handoff item.
2. **orchestra verify/audit**: stdout-only, no audit file.
3. **pi**: no git fields — weakest commit correlation.
4. **codex sqlite stores**: unexplored; may duplicate/extend rollouts.
5. **retention**: unbounded everywhere; plan for backfill, never assume a window.
6. **agy**: glog text only; conversation DBs unparsed in v1.
