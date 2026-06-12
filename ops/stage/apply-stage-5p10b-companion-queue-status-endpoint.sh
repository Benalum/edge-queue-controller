#!/usr/bin/env bash
cd "$HOME/Desktop/edge-queue-controller" || return 1
bash ops/dev/restart-controller-7070.sh || return 1
if bash ops/smoke/check-stage-5p10b-companion-queue-status-endpoint.sh; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
