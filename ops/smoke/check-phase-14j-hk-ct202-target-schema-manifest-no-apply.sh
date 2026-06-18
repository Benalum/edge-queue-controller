#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hk-ct202-target-schema-manifest-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

require_present() {
  local needle="$1"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$DOC"
  echo "PASS: $needle"
}

require_absent() {
  local needle="$1"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$DOC"; then
    echo "FAIL: unexpected text present: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

require_present 'Phase 14J-HK - CT202 target schema manifest, no apply'
require_present 'Previous checkpoint: Phase 14J-HJ at commit `b428ceb`'
require_present 'APPROVE_PHASE_14J_HK_CT202_TARGET_SCHEMA_MANIFEST_NO_APPLY'
require_present 'This phase does not execute a rebuild.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not authorize schema apply'
require_present 'This phase is docs/smoke only.'
require_present 'CT202 current DB is not treated as schema truth.'
require_present 'CT202-only wallet tables are not treated as authoritative'
require_present 'include current laptop continuity schema groups'
require_present 'Target include list'
require_present 'The target schema manifest includes these `39` laptop continuity tables'
require_present '`ad_reward_events`'
require_present '`app_user_preferences`'
require_present '`app_users`'
require_present '`calendar_events`'
require_present '`credit_reservations`'
require_present '`global_phrase_bank`'
require_present '`gpu_session_quotes`'
require_present '`gpu_sessions`'
require_present '`intent_definitions`'
require_present '`intent_routes`'
require_present '`job_results`'
require_present '`jobs`'
require_present '`password_reset_tokens`'
require_present '`pending_email_signups`'
require_present '`power_auto_state`'
require_present '`power_events`'
require_present '`power_idle_state`'
require_present '`router_feedback`'
require_present '`router_logs`'
require_present '`router_resolution_steps`'
require_present '`study_cards`'
require_present '`study_deck_totals`'
require_present '`study_decks`'
require_present '`study_reviews`'
require_present '`study_session_events`'
require_present '`study_sessions`'
require_present '`study_user_totals`'
require_present '`support_messages`'
require_present '`support_tickets`'
require_present '`user_credit_ledger`'
require_present '`user_language_preferences`'
require_present '`user_phrase_bank`'
require_present '`user_secondary_languages`'
require_present '`user_sessions`'
require_present '`user_usage_limits`'
require_present '`web_power_policy_events`'
require_present '`web_presence`'
require_present '`worker_events`'
require_present '`workers`'
require_present 'Target omit/defer list'
require_present 'omits or defers these CT202-only tables'
require_present '`credit_ledger`'
require_present '`user_credit_wallets`'
require_present 'target should match laptop/current runtime-compatible `workers` schema'
require_present 'include current lane/default-off metadata columns'
require_present 'target should be explicitly designed from current runtime code and laptop continuity evidence'
require_present 'This manifest is schema-only.'
require_present 'runtime row policy is documented'
require_present 'CT202 service remains disabled/inactive'
require_present 'cutover gate remains closed'
require_present 'Phase 14J-HL - CT202 rebuild backup and rollback plan, no apply'
require_present 'APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY'
require_present 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present 'This phase does not open the cutover gate.'
require_present 'This phase does not select a data authority path.'
require_present 'This phase does not authorize Path C execution.'
require_present 'This phase does not authorize a CT202 rebuild.'
require_present 'This phase does not authorize a schema apply.'
require_present 'Do not run migration/import/copy/dump from this phase.'

require_present 'CT202 authority cutover'
require_present 'data authority path selection'
require_present 'Path C execution'
require_present 'CT202 rebuild execution'
require_present 'CT202 data migration or import'
require_present 'schema migration'
require_present 'SQLite open'
require_present 'SQLite copy'
require_present 'SQL dump'
require_present 'table data dump'
require_present 'row content output'
require_present 'live laptop DB mutation'
require_present 'CT202 DB mutation'
require_present 'backup creation'
require_present 'restore operation'
require_present '`systemctl start`'
require_present '`systemctl enable`'
require_present 'CT202 onboot/autostart mutation'
require_present 'Cloudflare, DNS, or tunnel mutation'
require_present 'public route mutation'
require_present 'laptop controller stop or pause'
require_present 'CT101 call'
require_present 'model/Ollama endpoint call'
require_present 'worker start'
require_present 'production DB/job mutation'
require_present 'secret generation, printing, or installation'
require_present 'destructive GitHub branch or repository deletion'

require_absent 'APPROVE_CUTOVER_APPLY'
require_absent 'APPROVE_DATA_MIGRATION'
require_absent 'APPROVE_RUNTIME_APPLY'
require_absent 'APPROVE_ROUTE_APPLY'
require_absent 'APPROVE_CLOUDFLARE_APPLY'
require_absent 'APPROVE_SECRET_APPLY'
require_absent 'APPROVE_REBUILD_APPLY'
require_absent 'APPROVE_SCHEMA_APPLY'
require_absent 'systemctl enable edge-queue-controller.service'
require_absent 'pct set 202 -onboot 1'
require_absent 'cloudflare tunnel route'
require_absent 'cloudflared tunnel route'
require_absent 'ollama serve'
require_absent 'sqlite3 edge_queue.sqlite3 .dump'

echo "PASS: ${PHASE}"
