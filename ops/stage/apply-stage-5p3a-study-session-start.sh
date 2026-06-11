#!/usr/bin/env bash
cd "$HOME/Desktop/edge-queue-controller" || return 1
bash ops/smoke/check-stage-5p3a-study-session-start.sh
return 0 2>/dev/null || true
