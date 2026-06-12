#!/usr/bin/env bash
cd "$HOME/Desktop/edge-queue-controller" || exit 1
bash ops/smoke/check-stage-5p11s-presence-send-fallback.sh
