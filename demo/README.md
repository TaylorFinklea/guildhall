# Guildhall four-tool demo

This no-metered vertical slice exercises the current operational suite with
real binaries and read-only inputs. It never dispatches a model or mutates a
target repository.

```bash
demo/run.sh --help
demo/run.sh --build
demo/run.sh all
demo/run.sh undertake
```

## Pipeline

| Order | Tool | Command | Contract |
|---:|---|---|---|
| 1 | **Musterroll** | `musterroll status --json` | Reports configured execution profiles and current eligibility. |
| 2 | **Undertake** | `undertake config check --config ~/git/undertake/undertake.toml` | Validates the orchestrator configuration against the roster boundary. |
| 3 | **Afterfact** | `afterfact events --since 24h` | Emits normalized, artifact-pinned evidence. |
| 4 | **Cautionlight** | `cautionlight inspect --stdin` | Reads the evidence stream and emits advisory findings without writes. |

The full run pipes Afterfact directly into Cautionlight. Cautionlight exit 1 is
a documented incomplete-coverage result and is shown without being mislabeled
as a schema or usage failure; exit 2 remains fatal.

For an isolated smoke, set `GUILDHALL_BIN_DIR` to a directory containing the
four binaries and `GUILDHALL_GIT_ROOT` to the checkout root.
