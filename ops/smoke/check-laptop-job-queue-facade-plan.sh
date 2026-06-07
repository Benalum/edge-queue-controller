#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop-owned job queue facade plan static check ==="

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/laptop-job-queue-facade-plan.md
require_file docs/laptop-app-schema-foundation.md
require_file docs/laptop-postgres-backup-restore.md
require_file ops/db/laptop-app-schema-v1.sql

require_fixed docs/laptop-job-queue-facade-plan.md "laptop/controller owns durable app_jobs" "laptop owns durable jobs"
require_fixed docs/laptop-job-queue-facade-plan.md "CT101 workers become execution nodes" "CT101 workers execution only"
require_fixed docs/laptop-job-queue-facade-plan.md "user can submit work while CT101 is offline" "offline queue behavior"
require_fixed docs/laptop-job-queue-facade-plan.md "POST /api/controller/internal/jobs/claim" "future claim endpoint planned"
require_fixed docs/laptop-job-queue-facade-plan.md "POST /api/controller/internal/jobs/{job_id}/complete" "future complete endpoint planned"
require_fixed docs/laptop-job-queue-facade-plan.md "token stored outside git" "worker token outside git"
require_fixed docs/laptop-job-queue-facade-plan.md "ollama_chat" "first job type planned"
require_fixed docs/laptop-job-queue-facade-plan.md "Do not let both CT101 and laptop queues accept the same production job type" "duplicate queue warning"
require_fixed docs/laptop-job-queue-facade-plan.md "synthetic laptop job insert/read/delete smoke" "future synthetic smoke"
require_fixed docs/laptop-job-queue-facade-plan.md "Cleanup must wait until" "cleanup gating"
require_fixed docs/laptop-job-queue-facade-plan.md "Do not:" "Stage 5E-1 constraints"
require_fixed docs/laptop-job-queue-facade-plan.md "connect CT101 workers to laptop yet" "no worker migration yet"

require_fixed ops/db/laptop-app-schema-v1.sql "CREATE TABLE IF NOT EXISTS app_jobs" "app_jobs schema exists"
require_fixed ops/db/laptop-app-schema-v1.sql "CREATE TABLE IF NOT EXISTS app_workers" "app_workers schema exists"
require_fixed ops/db/laptop-app-schema-v1.sql "CREATE TABLE IF NOT EXISTS app_worker_nodes" "app_worker_nodes schema exists"

echo "PASS: laptop-owned job queue facade plan markers are present"
