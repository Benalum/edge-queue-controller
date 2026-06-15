#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

run_one() {
  local label="$1"
  local script="$2"

  if [ ! -x "$script" ]; then
    echo "FAIL: missing or not executable: $script"
    return 1
  fi

  EDGE_SMOKE_SKIP_DEPS=1 ops/smoke/run-quiet.sh "$label" "$script"
}

case "${1:-}" in
  profile)
    run_one phase-13p ops/smoke/check-phase-13p-disabled-voice-settings-contract.sh
    run_one phase-13q ops/smoke/check-phase-13q-disabled-profile-study-preferences-contract.sh
    run_one phase-13r ops/smoke/check-phase-13r-disabled-profile-preferences-schema-design.sh
    run_one phase-13s ops/smoke/check-phase-13s-disabled-profile-preferences-read-endpoint-contract.sh
    run_one phase-13t ops/smoke/check-phase-13t-disabled-profile-preferences-write-endpoint-contract.sh
    run_one phase-13u ops/smoke/check-phase-13u-disabled-profile-preferences-ui-support-contract.sh
    ;;

  *)
    echo "usage: ops/smoke/run-stack-quiet.sh profile"
    exit 2
    ;;
esac

echo "PASS: quiet stack completed: $1"
