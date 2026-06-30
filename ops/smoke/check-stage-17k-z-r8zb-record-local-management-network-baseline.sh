#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r8zb-record-local-management-network-baseline.md"

test -f "$DOC"

grep -q "Local Management Network Baseline" "$DOC"
grep -q "dev tailscale0 table 51820" "$DOC"
grep -q "wg-quick strip /etc/wireguard/home.conf" "$DOC"
grep -q "pvew" "$DOC"
grep -q "website-edge" "$DOC"
grep -q "Permission denied" "$DOC"

echo "stage-17k-z-r8zb smoke ok"
