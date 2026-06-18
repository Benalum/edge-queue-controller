#!/usr/bin/env bash
set -euo pipefail

# Phase 14J-HP - CT202 rebuild script artifact, no apply
#
# This artifact is intentionally safe-by-default.
# It verifies prerequisites and prints a no-apply rebuild plan summary only.
# It does not rebuild CT202, does not apply schema, does not restore, does not import data,
# does not start/enable services, does not mutate onboot, does not touch routes, and does not
# open SQLite with sqlite3.

PHASE="phase-14j-hp-ct202-rebuild-script-artifact-no-apply"
REQUIRED_APPROVAL="APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY"
BACKUP_DIR="/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z"
EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"
EXPECTED_DB_SIZE="262144"

approval="${APC_HP_APPROVAL:-}"
allow_dirty="${APC_ALLOW_DIRTY:-0}"

echo "=== ${PHASE} ==="
echo "MODE=no_apply_prerequisite_and_plan_check_only"
echo "NO restore"
echo "NO rebuild"
echo "NO cutover/apply"
echo "NO data authority path selection"
echo "NO Path C execution"
echo "NO CT202 rebuild execution"
echo "NO CT202 schema apply"
echo "NO CT202 data migration/import"
echo "NO SQLite open with sqlite3"
echo "NO SQL dump"
echo "NO table data dump"
echo "NO row content output"
echo "NO live laptop DB mutation"
echo "NO CT202 DB mutation"
echo "NO backup creation"
echo "NO restore operation"
echo "NO systemctl start"
echo "NO systemctl enable"
echo "NO CT202 onboot/autostart mutation"
echo "NO VM start/stop/reboot"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO public route mutation"
echo "NO laptop controller stop/pause"
echo "NO CT101/model/Ollama/worker call"
echo "NO worker start"
echo "NO production DB/job mutation"
echo "NO secrets printed"
echo "NO destructive GitHub branch/repository deletion"

echo
echo "=== approval guard ==="
if [ "$approval" != "$REQUIRED_APPROVAL" ]; then
  echo "FAIL: APC_HP_APPROVAL must equal required no-apply artifact approval phrase"
  exit 1
fi
echo "PASS: no-apply artifact approval phrase confirmed"

echo
echo "=== optional repo guard ==="
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  repo_root="$(git rev-parse --show-toplevel)"
  cd "$repo_root"

  head_now="$(git rev-parse --short HEAD)"
  origin_main_local="$(git rev-parse --short origin/main 2>/dev/null || true)"
  status_short="$(git status --short)"

  echo "repo_root=$repo_root"
  echo "head_now=$head_now"
  echo "origin_main_local=${origin_main_local:-unknown}"
  echo "git_status_short=${status_short:-<clean>}"

  if [ -n "${APC_EXPECTED_HEAD:-}" ]; then
    test "$head_now" = "$APC_EXPECTED_HEAD"
    if [ -n "$origin_main_local" ]; then
      test "$origin_main_local" = "$APC_EXPECTED_HEAD"
    fi

    if [ -n "$status_short" ] && [ "$allow_dirty" != "1" ]; then
      echo "FAIL: repo is dirty and APC_ALLOW_DIRTY is not set"
      exit 1
    fi

    if [ -n "$status_short" ] && [ "$allow_dirty" = "1" ]; then
      echo "PASS: expected dirty repo allowed for pre-commit artifact smoke"
    else
      echo "PASS: repo clean for expected checkpoint guard"
    fi

    echo "PASS: optional expected repo checkpoint guard passed"
  else
    echo "PASS: repo detected; no explicit APC_EXPECTED_HEAD guard requested"
  fi
else
  echo "PASS: no git repo detected; repo guard skipped"
fi

echo
echo "=== pveso resolution design summary ==="
echo "This artifact is designed to use the SSH/Tailscale fallback resolver from HM/HN when remote verification is added."
echo "This artifact does not open a remote connection in HP."

echo
echo "=== backup prerequisite summary ==="
echo "expected_backup_dir=$BACKUP_DIR"
echo "expected_db_size=$EXPECTED_DB_SIZE"
echo "expected_db_sha256=$EXPECTED_DB_SHA256"
echo "Required backup artifacts from HM/HN:"
echo "- ct202-edge_queue.sqlite3"
echo "- ct202-pct-config.txt"
echo "- ct202-app-summary.txt"
echo "- ct202-service-summary.txt"
echo "- ct202-env-config-posture.txt"
echo "- rollback-checklist.txt"
echo "- manifest.txt"

echo
echo "=== target manifest summary ==="
echo "Target schema source: Phase 14J-HK target manifest plus current runtime/laptop continuity evidence."
echo "Target include count: 39 laptop continuity tables."
echo "Target omit/defer CT202-only drift tables:"
echo "- credit_ledger"
echo "- user_credit_wallets"

echo
echo "=== required target include table list ==="
cat <<'TABLES'
ad_reward_events
app_user_preferences
app_users
calendar_events
credit_reservations
global_phrase_bank
gpu_session_quotes
gpu_sessions
intent_definitions
intent_routes
job_results
jobs
password_reset_tokens
pending_email_signups
power_auto_state
power_events
power_idle_state
router_feedback
router_logs
router_resolution_steps
study_cards
study_deck_totals
study_decks
study_reviews
study_session_events
study_sessions
study_user_totals
support_messages
support_tickets
user_credit_ledger
user_language_preferences
user_phrase_bank
user_secondary_languages
user_sessions
user_usage_limits
web_power_policy_events
web_presence
worker_events
workers
TABLES

echo
echo "=== critical mismatch decisions ==="
echo "workers: target current runtime-compatible laptop shape; include lane/default-off metadata columns; do not treat CT202 21-column shape as authority."
echo "credit_reservations: target current runtime/laptop continuity shape; do not automatically preserve CT202 extra columns as authority."
echo "credit_ledger/user_credit_wallets: omit or defer unless a later credit redesign explicitly adopts them."

echo
echo "=== forbidden operations check summary ==="
echo "This artifact contains no rebuild implementation and no schema apply implementation."
echo "This artifact contains no restore implementation and no data import implementation."
echo "This artifact is a no-apply prerequisite and plan check only."

echo
echo "=== ${PHASE} result ==="
echo "PASS: no-apply rebuild script artifact ran safely"
echo "PASS: no restore/rebuild/schema apply performed"
echo "PASS: no data authority path selected"
echo "PASS: no SQLite DB opened with sqlite3"
echo "PASS: no SQL dump or row content output"
echo "PASS: no service start/enable or onboot mutation"
echo "PASS: no route/cutover mutation"
