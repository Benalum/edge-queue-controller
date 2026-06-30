#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8e-deploy-backend-closed-beta-registration-gate-ct203.md"

echo "=== Stage 17K-Z-R8E deploy record smoke ==="

test -f "$DOC"
grep -Fq "Stage 17K-Z-R8E" "$DOC"
grep -Fq "closed_beta_signup_disabled" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"
grep -Fq "/opt/edge-queue-controller/releases/head-a39021f/edge_controller.py" "$DOC"
grep -Fq "Buddies Who Study" "$DOC"
grep -Fq "PASS_CT203_R8E_TARGETED_DEPLOY_RESTART" "$DOC"
grep -Fq "curl -f" "$DOC"

echo "PASS Stage 17K-Z-R8E deploy record smoke"
