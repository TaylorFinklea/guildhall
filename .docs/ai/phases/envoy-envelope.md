# Envoy message envelope — v1

**Status**: charter spec (2026-07-01). Transport-ready by design; v1 transport
is "a file on disk + an in-process dispatch" per the substrate principle. Live
transports (agent-bus on Scadrial — exists, broken end-to-end; MCP for
tool-shaped queries, e.g. tesela-mcp) are named future carriers, not v1 work.

## Envelope

```json
{
  "envelope": "guildhall/envoy@1",
  "id": "env-<ulid>",
  "ts": "RFC3339",
  "kind": "question | answer | notice",
  "from": {"hall": "conductor|hindsight|human|…", "agent": "model-or-person", "session_ref": "transcript path?"},
  "to":   {"repo": "/abs/path", "hall": "…?"},
  "reply_to": "env-… (answers/notices only)",
  "deadline": "RFC3339?",
  "constraints": {"read_only": true, "max_minutes": 15},
  "question": {
    "text": "one specific question, answerable from the target repo",
    "schema": { "…optional JSON Schema the answer.value must satisfy…" }
  },
  "answer": {
    "value": "…string or schema-shaped object…",
    "confidence": "high|medium|low",
    "evidence": [{"path": "file", "line": 0, "note": "…"}],
    "gaps": ["what could not be determined and why"]
  }
}
```

Rules:
- `read_only: true` is the default and v1-only mode. A consult NEVER mutates
  the target repo, its beads, or its docs.
- Answers cite evidence (`path:line`) or declare gaps — same fail-closed ethos
  as everywhere: an unsupported answer is a gap, not a guess.
- Envelopes are files: `<target-repo>/ai-scratch/envoy/<id>.json` while in
  flight (ai-scratch is globally gitignored — consult traffic never enters
  history), archived by the asker if worth keeping.
- The consult agent is primed the way a native session would be: cwd = target
  repo, `bd prime`, the repo's AGENTS.md/CLAUDE.md + `.docs/ai/` — "wear the
  repo's shoes." Its tier must satisfy the question's difficulty; when unsure,
  senior.

## v1 deliverable (envoy repo)

The skill CONTENT (`skill/SKILL.md` + envelope schema + dispatch recipe) lives
in `~/git/envoy`; installation into `~/.claude/skills` is chezmoi territory →
pending-human handoff item. Conformance = a golden envelope pair validated in
tests.
