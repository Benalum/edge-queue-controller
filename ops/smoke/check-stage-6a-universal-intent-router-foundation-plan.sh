#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-6a-universal-intent-router-foundation-plan.md"

echo "=== Stage 6A smoke: Universal Intent Router foundation plan ==="

test -f "$DOC"

grep -q "Stage 6A Universal Intent Router Foundation Plan" "$DOC"
grep -q "This stage does not change runtime behavior" "$DOC"
grep -q "Permanent Router Contract" "$DOC"
grep -q "Initial Supported Domains" "$DOC"
grep -q "First Implementation Target" "$DOC"
grep -q "Router Layers" "$DOC"
grep -q "Multilingual Requirements" "$DOC"
grep -q "User Language Preferences" "$DOC"
grep -q "Initial Database Tables" "$DOC"
grep -q "Initial API Design" "$DOC"
grep -q "Safety Rules" "$DOC"
grep -q "Logging Requirements" "$DOC"
grep -q "Migration Strategy" "$DOC"
grep -q "Feature Flags" "$DOC"
grep -q "Rollback Strategy" "$DOC"
grep -q "Stage 6A Acceptance Criteria" "$DOC"

grep -q "study.card.skip" "$DOC"
grep -q "calendar_action_drafts" "$DOC"
grep -q "tool_registry" "$DOC"
grep -q "agent_runs" "$DOC"
grep -q "POST /api/router/resolve" "$DOC"
grep -q "ROUTER_ENABLED" "$DOC"

echo "PASS: Stage 6A router foundation planning checkpoint is present."
