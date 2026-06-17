#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-fb-install-baseline-packages-on-website-edge.md"

echo "=== Phase 14J-FB smoke: baseline package install record ==="

test -f "$DOC"

require_marker() {
  local marker="$1"
  if grep -Fq -- "$marker" "$DOC"; then
    echo "PASS: marker present: $marker"
  else
    echo "FAIL: marker missing: $marker" >&2
    exit 1
  fi
}

require_marker "Phase 14J-FB - Install baseline packages on website-edge"
require_marker "hostname=website-edge"
require_marker "os_version=26.04"
require_marker "qemu-guest-agent"
require_marker "python3-venv"
require_marker "nginx"
require_marker "qemu_guest_agent_start_rc=0"
require_marker "nginx_start_rc=0"
require_marker "PASS: package installed: qemu-guest-agent"
require_marker "PASS: package installed: python3-venv"
require_marker "PASS: package installed: nginx"
require_marker "qemu-guest-agent.service enabled=static active=active"
require_marker "nginx.service enabled=enabled active=active"
require_marker "nginx_local_http_status=200"
require_marker "PASS: nginx responds locally"
require_marker "PASS: command absent after install: docker"
require_marker "PASS: command absent after install: cloudflared"
require_marker "PASS: command absent after install: node"
require_marker "PASS: command absent after install: npm"
require_marker "PHASE_14J_FB_RESULT=passed"
require_marker "phase_exit_code=0"
require_marker "Docker remains absent"
require_marker "cloudflared remains absent"
require_marker "Node/npm remain absent"
require_marker "No app repo has been cloned to"
require_marker "No app has been deployed"
require_marker "No Cloudflare test route or production cutover has occurred"
require_marker "No controller/queue migration has occurred"
require_marker "No worker start or runtime activation has occurred"
require_marker "No production DB/job mutation has occurred"
require_marker "No CT101/model/Ollama call has occurred"
require_marker "No Tailscale ACL/grants/tag mutation or Tailscale SSH mode enablement occurred"
require_marker "No rerun of Phase 14J-AG apply wrapper"

echo "PASS: Phase 14J-FB install record is complete"
