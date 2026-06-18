#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ha-read-only-current-authority-and-edge-posture-inventory"
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

require_present "Phase 14J-HA - Read-only current authority and edge posture inventory"
require_present "Previous checkpoint: Phase 14J-GZ at commit \`ccfad10\`"
require_present "This phase records evidence only."
require_present "The laptop remains the live controller and queue authority."
require_present "laptop loopback port \`7070\` open for the controller"
require_present "laptop loopback port \`8787\` open for the wrapper UI"
require_present "laptop loopback port \`8765\` open for Project Pilot Bridge"
require_present "laptop-local \`edge_queue.sqlite3\` quick_check was \`ok\`"
require_present "laptop application table count was \`39\`"
require_present "\`jobs\`: \`22\`"
require_present "\`workers\`: \`2\`"
require_present "\`user_sessions\`: \`233\`"
require_present "\`router_logs\`: \`0\`"
require_present "Public website paths responded read-only with HTTP \`200\`"
require_present "CT201 \`edge-data\` posture:"
require_present "status: stopped"
require_present "hostname: \`edge-data\`"
require_present "CT202 owner node was found as \`pveso\`."
require_present "status: running container"
require_present "hostname: \`edge-controller\`"
require_present "\`edge-queue-controller.service\` is \`disabled\`"
require_present "\`edge-queue-controller.service\` is \`inactive\`"
require_present "no checked controller/smoke listener active on loopback ports \`7070\`, \`17070\`, \`17071\`, or \`17072\`"
require_present "CT202 SQLite candidate DB quick_check was \`ok\`"
require_present "CT202 application table count was \`25\`"
require_present "CT202 remains a private controller candidate only and is not authoritative."
require_present "VM 200 owner node was found as \`pvew\`."
require_present "name: \`website-edge\`"
require_present "qemu guest agent responded"
require_present "network bridge: \`vmbr0\`"
require_present "VM 200 remains the public/static website edge role only."
require_present "laptop controller remains live controller/queue authority"
require_present "laptop-local \`edge_queue.sqlite3\` remains live primary controller platform data authority"
require_present "The CT202 controller cutover readiness gate remains CLOSED."
require_present "This phase does not open the cutover gate."

require_present "CT202 authority cutover"
require_present "CT202 data migration or import"
require_present "\`systemctl start\`"
require_present "\`systemctl enable\`"
require_present "CT202 onboot/autostart mutation"
require_present "Cloudflare, DNS, or tunnel mutation"
require_present "public route mutation"
require_present "laptop controller stop or pause"
require_present "live laptop DB mutation"
require_present "CT101 call"
require_present "model/Ollama endpoint call"
require_present "worker start"
require_present "production DB/job mutation"
require_present "secret generation, printing, or installation"
require_present "destructive GitHub branch or repository deletion"

require_absent "APPROVE_CUTOVER_APPLY"
require_absent "APPROVE_DATA_MIGRATION"
require_absent "APPROVE_RUNTIME_APPLY"
require_absent "APPROVE_ROUTE_APPLY"
require_absent "APPROVE_CLOUDFLARE_APPLY"
require_absent "APPROVE_SECRET_APPLY"
require_absent "systemctl enable edge-queue-controller.service"
require_absent "pct set 202 -onboot 1"
require_absent "cloudflare tunnel route"
require_absent "cloudflared tunnel route"
require_absent "ollama serve"
require_absent "sqlite3 edge_queue.sqlite3 .dump"

echo "PASS: ${PHASE}"
