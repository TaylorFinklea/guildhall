# Spec-writer briefing (Guildhall component specs)

You are writing `<repo>/.docs/ai/phases/<name>-v1-spec.md` for one guild member
and seeding its beads backlog. Read FIRST: `~/git/guildhall/README.md`
(charter — especially the invariants), and the two shared specs if your
component touches them (`ingestion-event-model.md`, `envoy-envelope.md`).
Mirror the structure and register of the reference spec:
`~/git/harness-conductor/.docs/ai/phases/conductor-v1-spec.md`.

## Spec structure (mirror it)

Mission (one paragraph) · Locked decisions table · Ground truth (recon facts
with paths/file:line — your prompt supplies a digest; verify any path you cite
with a quick ls/grep before writing it) · Invariants (testable, numbered) ·
Architecture (small modules, one purpose each) · Milestones (M0..Mn, each
independently shippable with a runnable Verify) · Precedents to read (name the
pattern + exact path; "mirror X", never invented code blocks) · Deferred/non-goals.

## Plan-writing discipline (from ~/AGENTS.md — binding)

- Spec-derived (schemas, invariants, milestones, acceptance): specify exactly.
- Codebase-derived (helper signatures, idioms): DO NOT prescribe code you
  haven't grepped. Name the file to mirror and require the implementer to read
  it. If your prompt's digest cites file:line, spot-check it exists before
  embedding it in the spec.

## Bead seeding recipe (exact)

In the component repo (its bd prefix = repo name):

```
bd create --id <prefix>-<slug> -t task -p <1|2> -e <minutes> \
  --title "M0: …" \
  -d "Read .docs/ai/phases/<name>-v1-spec.md § <section> FIRST. Scope: … Acceptance: …" \
  --acceptance "…" \
  --notes "tier_floor: <t> · complexity: <C> · verify_cmd: <cmd> · spec: § <section>" \
  --metadata '{"tier_floor":"<lead|senior|junior>","complexity":"<S|M|L|XL>","verify_cmd":"<runnable shell command>"}' < /dev/null
```

Then wire deps: `bd dep add <issue> <blocker> < /dev/null` (issue is
blocked-by blocker). Rules: every bead has a RUNNABLE verify_cmd (no
verify → it doesn't get created; human-verify tails go in the notes);
metadata AND notes-prose both carry routing; 5–10 beads is the right
count for an MVP — bounded items a Senior model finishes in ≤ ~3h;
`tier_floor: lead` only for genuinely irreducible design/review beads;
round up complexity when unsure. NEVER run `bd ready --claim`. NEVER touch
any repo other than your component repo.

## Language/runtime guidance

Default for code-bearing members: Rust mirroring
`~/git/harness-conductor` + `~/git/larkline` discipline (serde/serde_json,
no tokio unless justified in an ADR). Members whose MVP is
content/scripts (envoy) or where recon argues otherwise: justify in the
repo's decisions.md. Do not add dependencies without an ADR entry.

## Finish

Update the repo's `.docs/ai/roadmap.md` (Vision one-liner + Now = first
beads) and `current-state.md` (≤20 lines). ONE commit: spec + docs
("<name>: v1 spec + seeded backlog (N beads)"). Run `bd ready < /dev/null`
and include its output in your final summary. Never push.
