#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r9g-record-website-edge-jkg76nid-ssh-alias-fix.md"

test -f "$DOC"

grep -q "Website-Edge jkg76nid SSH Alias Fix" "$DOC"
grep -q "website-edge" "$DOC"
grep -q "jkg76nid" "$DOC"
grep -q "PermitRootLogin no" "$DOC"
grep -q "tailscale0 table 51820" "$DOC"
grep -q "100.105.133.69" "$DOC"
grep -q "100.127.73.75" "$DOC"
grep -q "BindAddress 100.108.171.94" "$DOC"

echo "stage-17k-z-r9g smoke ok"
