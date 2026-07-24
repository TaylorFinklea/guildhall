#!/usr/bin/env bash
set -euo pipefail

ROOT=${GUILDHALL_GIT_ROOT:-$HOME/git}
BIN_DIR=${GUILDHALL_BIN_DIR:-}
ORDER=(musterroll undertake afterfact cautionlight)

usage() {
  cat <<'EOF'
usage: demo/run.sh [all|--build|--help|musterroll|undertake|afterfact|cautionlight]

Runs the no-metered Guildhall vertical slice:
  musterroll status -> undertake config check -> afterfact events -> cautionlight inspect

Environment:
  GUILDHALL_GIT_ROOT  checkout root (default: $HOME/git)
  GUILDHALL_BIN_DIR   directory containing all four binaries
EOF
}

binary_path() {
  local name=$1
  if [[ -n "$BIN_DIR" ]]; then
    printf '%s/%s\n' "$BIN_DIR" "$name"
  else
    printf '%s/%s/target/release/%s\n' "$ROOT" "$name" "$name"
  fi
}

require_binary() {
  local path
  path=$(binary_path "$1")
  [[ -x "$path" ]] || {
    printf 'missing binary: %s (run demo/run.sh --build)\n' "$path" >&2
    return 1
  }
}

build_all() {
  local name
  [[ -z "$BIN_DIR" ]] || {
    printf '%s\n' '--build cannot be used with GUILDHALL_BIN_DIR' >&2
    return 2
  }
  for name in "${ORDER[@]}"; do
    cargo build --release --manifest-path "$ROOT/$name/Cargo.toml"
  done
}

section() {
  printf '\n== %s ==\n' "$1"
}

demo_musterroll() {
  section 'Musterroll: provider eligibility'
  "$(binary_path musterroll)" status --json
}

demo_undertake() {
  section 'Undertake: validated suite configuration'
  "$(binary_path undertake)" config check --config "$ROOT/undertake/undertake.toml"
}

demo_afterfact() {
  section 'Afterfact: normalized evidence stream'
  "$(binary_path afterfact)" events --since 24h
}

demo_cautionlight() {
  section 'Afterfact -> Cautionlight: read-only advice'
  local producer_status consumer_status
  local -a statuses
  set +e
  "$(binary_path afterfact)" events --since 24h | "$(binary_path cautionlight)" inspect --stdin
  statuses=("${PIPESTATUS[@]}")
  producer_status=${statuses[0]}
  consumer_status=${statuses[1]}
  set -e
  [[ "$producer_status" -eq 0 ]] || return "$producer_status"
  case "$consumer_status" in
    0|1) return 0 ;;
    *) return "$consumer_status" ;;
  esac
}

case ${1:-all} in
  --help|-h|help)
    usage
    ;;
  --build)
    build_all
    ;;
  all)
    for name in "${ORDER[@]}"; do require_binary "$name"; done
    demo_musterroll
    demo_undertake
    demo_cautionlight
    ;;
  musterroll|undertake|afterfact|cautionlight)
    require_binary "$1"
    if [[ "$1" == cautionlight ]]; then require_binary afterfact; fi
    "demo_$1"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
