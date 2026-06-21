#!/usr/bin/env bash
# AI Platform Control PPB checksum-gated script runner.
#
# Usage from a PPB block:
#   cd ~/Desktop/edge-queue-controller
#   source ops/ppb/ppb-sha256-runner.sh
#   ppb_sha256_run "$HOME/Downloads/script-name.sh" "expected_sha256"
#
# This helper is intentionally local-only. It verifies a downloaded script
# before bash executes it and refuses to run when the checksum does not match.

ppb_sha256_run() {
  local script_path="$1"
  local expected_sha256="$2"

  echo "=== checksum gate ==="
  echo "script=$script_path"

  if [ ! -f "$script_path" ]; then
    echo "SCRIPT_NOT_FOUND_REFUSING_TO_RUN"
    return 101
  fi

  local actual_sha256
  actual_sha256="$(sha256sum "$script_path" | awk '{print $1}')"

  echo "expected=$expected_sha256"
  echo "actual=$actual_sha256"

  if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "CHECKSUM_MISMATCH_REFUSING_TO_RUN"
    return 100
  fi

  echo "CHECKSUM_OK_RUNNING_SCRIPT"
  bash "$script_path"
}
