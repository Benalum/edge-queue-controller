#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

echo "=== phase-12r-q-live-disabled-admin-warmup-refusal-smoke: superseded ==="
echo "CHECK: Phase 12R-Q is superseded by Phase 12R-U after admin-auth boundary rollout."
echo "CHECK: Delegating to Phase 12R-U live admin-auth bound warmup smoke."

exec ops/smoke/check-phase-12r-u-live-admin-auth-bound-warmup-smoke.sh
