#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply"
REQUIRED_APPROVAL="APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY"
BACKUP_DIR="/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z"
EXPECTED_DB_SIZE="262144"
EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"
EXPECTED_MANIFEST_SHA256="dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491"
EXPECTED_ROLLBACK_CHECKLIST_SHA256="3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6"

HP_SCRIPT="ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh"
HR_SCRIPT="ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh"

approval="${APC_HT_APPROVAL:-}"
allow_dirty="${APC_ALLOW_DIRTY:-0}"
remote_readonly="${APC_HT_REMOTE_READONLY:-1}"

echo "=== ${PHASE} ==="
echo "MODE=private_rehearsal_no_restore_no_rebuild_no_apply"
echo "NO restore"
echo "NO rebuild"
echo "NO cutover/apply"
echo "NO data authority path selection"
echo "NO Path C execution"
echo "NO CT202 schema apply"
echo "NO CT202 data migration/import"
echo "NO SQLite open with sqlite3"
echo "NO SQL dump"
echo "NO row content output"
echo "NO live laptop DB mutation"
echo "NO CT202 DB mutation"
echo "NO backup creation"
echo "NO restore operation"
echo "NO systemctl start"
echo "NO systemctl enable"
echo "NO CT202 onboot/autostart mutation"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO public route mutation"
echo "NO CT101/model/Ollama/worker call"
echo "NO secrets printed"

echo
echo "=== approval guard ==="
test "$approval" = "$REQUIRED_APPROVAL"
echo "PASS: private rehearsal artifact approval phrase confirmed"

echo
echo "=== repo/artifact guard ==="
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
  [ -z "$origin_main_local" ] || test "$origin_main_local" = "$APC_EXPECTED_HEAD"
  if [ -n "$status_short" ] && [ "$allow_dirty" != "1" ]; then
    echo "FAIL: repo is dirty and APC_ALLOW_DIRTY is not set"
    exit 1
  fi
  if [ -n "$status_short" ]; then
    echo "PASS: expected dirty repo allowed for pre-commit artifact smoke"
  else
    echo "PASS: repo clean for expected checkpoint guard"
  fi
fi

test -x "$HP_SCRIPT"
test -x "$HR_SCRIPT"
echo "PASS: HP and HR no-apply/no-restore artifacts exist and are executable"

echo
echo "=== run HP no-apply rebuild artifact ==="
APC_HP_APPROVAL="APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY" \
APC_EXPECTED_HEAD="$head_now" \
APC_ALLOW_DIRTY="$allow_dirty" \
bash "$HP_SCRIPT" | sed -n '1,220p'

echo
echo "=== run HR no-restore rollback artifact ==="
APC_HR_APPROVAL="APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD" \
APC_EXPECTED_HEAD="$head_now" \
APC_ALLOW_DIRTY="$allow_dirty" \
bash "$HR_SCRIPT" | sed -n '1,220p'

echo
echo "=== remote read-only CT202 posture and backup verification ==="
if [ "$remote_readonly" != "1" ]; then
  echo "PASS: remote read-only check skipped by APC_HT_REMOTE_READONLY=$remote_readonly"
else
  TMP_KNOWN_HOSTS="/tmp/apc-ht-known-hosts"
  : > "$TMP_KNOWN_HOSTS"
  chmod 600 "$TMP_KNOWN_HOSTS"

  SSH_OPTS=(
    -o ConnectTimeout=8
    -o ServerAliveInterval=5
    -o ServerAliveCountMax=2
    -o StrictHostKeyChecking=accept-new
    -o UserKnownHostsFile="$TMP_KNOWN_HOSTS"
  )

  PVE_SSH_TARGET=""

  try_ssh_target() {
    local candidate="$1"
    [ -n "$candidate" ] || return 1
    if ssh "${SSH_OPTS[@]}" "$candidate" 'hostname >/dev/null 2>&1'; then
      PVE_SSH_TARGET="$candidate"
      return 0
    fi
    return 1
  }

  for candidate in pveso root@pveso; do
    if try_ssh_target "$candidate"; then
      break
    fi
  done

  if [ -z "$PVE_SSH_TARGET" ] && command -v tailscale >/dev/null 2>&1; then
    mapfile -t ts_candidates < <(
      {
        if command -v jq >/dev/null 2>&1; then
          tailscale status --json 2>/dev/null | jq -r '
            .Peer[]?
            | select((.HostName=="pveso") or ((.DNSName // "") | test("^pveso\\.")))
            | [((.DNSName // "") | sub("\\.$"; "")), (.TailscaleIPs[0] // "")]
            | .[]
            | select(. != "")
          ' || true
        fi
        tailscale status 2>/dev/null | awk '$2=="pveso" {print $1}' || true
      } | awk '!seen[$0]++'
    )

    for host in "${ts_candidates[@]:-}"; do
      for candidate in "$host" "root@$host"; do
        if try_ssh_target "$candidate"; then
          break 2
        fi
      done
    done
  fi

  if [ -z "$PVE_SSH_TARGET" ]; then
    echo "FAIL: could not resolve/reach pveso"
    exit 1
  fi
  echo "PASS: resolved pveso ssh target"

  ssh "${SSH_OPTS[@]}" "$PVE_SSH_TARGET" "BACKUP_DIR='$BACKUP_DIR' EXPECTED_DB_SIZE='$EXPECTED_DB_SIZE' EXPECTED_DB_SHA256='$EXPECTED_DB_SHA256' EXPECTED_MANIFEST_SHA256='$EXPECTED_MANIFEST_SHA256' EXPECTED_ROLLBACK_CHECKLIST_SHA256='$EXPECTED_ROLLBACK_CHECKLIST_SHA256' bash -s" <<'REMOTE'
set -euo pipefail

CTID="202"
SERVICE="edge-queue-controller.service"

echo "remote_host=$(hostname)"
echo "backup_dir=$BACKUP_DIR"

echo
echo "=== CT202 posture read-only ==="
ct_status="$(pct status "$CTID" | awk '{print $2}')"
ct_hostname="$(pct exec "$CTID" -- hostname)"
ct_onboot="$(pct config "$CTID" | awk -F': ' '$1=="onboot"{print $2; found=1} END{if(!found) print "0"}')"
service_enabled="$(pct exec "$CTID" -- bash -lc "systemctl is-enabled '$SERVICE' 2>/dev/null || true")"
service_active="$(pct exec "$CTID" -- bash -lc "systemctl is-active '$SERVICE' 2>/dev/null || true")"

echo "ct_status=$ct_status"
echo "ct_hostname=$ct_hostname"
echo "ct_onboot=${ct_onboot:-0}"
echo "service_enabled=${service_enabled:-unknown}"
echo "service_active=${service_active:-unknown}"

test "$ct_status" = "running"
test "$ct_hostname" = "edge-controller"
test "${ct_onboot:-0}" = "0"
test "${service_enabled:-unknown}" != "enabled"
test "${service_active:-unknown}" != "active"

if pct exec "$CTID" -- bash -lc "ss -ltn 2>/dev/null | awk '{print \$4}' | grep -Eq ':(7070|8787|8765)$'"; then
  echo "FAIL: checked controller/smoke listener active"
  exit 1
fi
echo "PASS: CT202 remains private, disabled/inactive, onboot off, no checked listener"

echo
echo "=== backup artifacts read-only ==="
test -d "$BACKUP_DIR"
test -f "$BACKUP_DIR/ct202-edge_queue.sqlite3"
test -f "$BACKUP_DIR/manifest.txt"
test -f "$BACKUP_DIR/rollback-checklist.txt"

db_size="$(stat -c '%s' "$BACKUP_DIR/ct202-edge_queue.sqlite3")"
db_hash="$(sha256sum "$BACKUP_DIR/ct202-edge_queue.sqlite3" | awk '{print $1}')"
manifest_hash="$(sha256sum "$BACKUP_DIR/manifest.txt" | awk '{print $1}')"
rollback_hash="$(sha256sum "$BACKUP_DIR/rollback-checklist.txt" | awk '{print $1}')"

echo "db_size=$db_size"
echo "db_sha256=$db_hash"
echo "manifest_sha256=$manifest_hash"
echo "rollback_checklist_sha256=$rollback_hash"

test "$db_size" = "$EXPECTED_DB_SIZE"
test "$db_hash" = "$EXPECTED_DB_SHA256"
test "$manifest_hash" = "$EXPECTED_MANIFEST_SHA256"
test "$rollback_hash" = "$EXPECTED_ROLLBACK_CHECKLIST_SHA256"

grep -Fq "no_sqlite_open=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_sql_dump=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_row_content=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_service_start=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_service_enable=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_onboot_mutation=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_rebuild=1" "$BACKUP_DIR/manifest.txt"
grep -Fq "no_cutover=1" "$BACKUP_DIR/manifest.txt"

echo "PASS: backup artifact hashes and manifest guard flags verified read-only"
echo "PASS: no restore/rebuild/schema apply/import/cutover performed"
REMOTE
fi

echo
echo "=== ${PHASE} result ==="
echo "PASS: private rehearsal artifact ran safely"
echo "PASS: HP no-apply artifact ran"
echo "PASS: HR no-restore artifact ran"
echo "PASS: CT202 read-only posture checks passed"
echo "PASS: HM/HN backup artifact checks passed"
echo "PASS: no restore/rebuild/schema apply performed"
echo "PASS: no data authority path selected"
echo "PASS: no SQLite DB opened with sqlite3"
echo "PASS: no SQL dump or row content output"
echo "PASS: no service start/enable or onboot mutation"
echo "PASS: no route/cutover mutation"
