# Guildhall operator guide

The operational suite is Undertake, Musterroll, Afterfact, and Cautionlight.
Build and invoke only those binaries from their matching repositories.

## Build

```bash
for tool in musterroll undertake afterfact cautionlight; do
  cargo build --release --manifest-path "$HOME/git/$tool/Cargo.toml"
done
```

A release build refreshes `target/release/<tool>`. Do not infer that an installed
binary changed merely because a debug test passed.

## Musterroll: roster and availability

```bash
musterroll status --json
musterroll roster snapshot --config "$HOME/git/musterroll/roster.toml" --json
```

Musterroll reports provider evidence and eligibility; it does not select a job,
choose fallback order, or mutate routing from scorecards. `unknown` remains
ineligible until trustworthy evidence or a bounded human action changes it.

## Undertake: approved jobs

```bash
CFG="$HOME/git/undertake/undertake.toml"
undertake config check --config "$CFG"
undertake status
undertake plan prepare --repo <repo> --artifact <request> \
  --output-kind spec --tier-floor lead --complexity XL --config "$CFG"
```

Undertake supports the closed job set `work`, `review`, `consult`, and `plan`.
Every job starts from an explicit target and pins its Musterroll snapshot,
approval, scope, role/stage routes, limits, and verifier. It never treats an
unrelated commit or a successful process exit as proof of completion.

## Afterfact: evidence and scorecards

```bash
afterfact db ingest
afterfact db integrity-check
afterfact events --since 24h
afterfact scorecard profile --job plan --json
```

Afterfact normalizes evidence and exposes artifact-pinned JSONL. Its SQLite
index is derived; raw artifacts and the append-only observation journal remain
canonical.

## Cautionlight: advisory findings

```bash
afterfact events --since 24h | cautionlight inspect --stdin
```

Cautionlight is read-only and stateless. Exit 0 means valid processing, exit 1
means incomplete coverage, and exit 2 means usage or schema failure. A finding
is advice and never changes execution state.

## No-metered suite smoke

```bash
demo/run.sh --help
demo/run.sh --build
demo/run.sh all
```

The smoke performs a Musterroll status read, Undertake config validation, and
an Afterfact-to-Cautionlight pipe. It does not dispatch a model.

## Operational cautions

- Stop if any required identity, schema, hash, eligibility fact, or approval is unknown.
- Keep one writer per target repository.
- Never push or apply managed HOME configuration from an automated run.
- Review provider status live; do not infer quota from model prose.
- Preserve immutable migration inputs and completed evidence byte-for-byte.
