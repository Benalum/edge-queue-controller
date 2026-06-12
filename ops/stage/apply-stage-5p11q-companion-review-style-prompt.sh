#!/usr/bin/env bash
cd "$HOME/Desktop/edge-queue-controller" || return 1
if bash ops/smoke/check-stage-5p11q-companion-review-style-prompt.sh; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
