#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r9d-record-vm200-normal-user-ssh-repair.md"

test -f "$DOC"

grep -q "VM200 Normal-User SSH Repair" "$DOC"
grep -q "website-edge" "$DOC"
grep -q "PermitRootLogin no" "$DOC"
grep -q "normal VM200 user" "$DOC"
grep -q "authorized_keys" "$DOC"
grep -q "qm guest exec" "$DOC"
grep -q "tailscale0" "$DOC"
grep -q "did not change" "$DOC"

echo "stage-17k-z-r9d normal-user ssh repair smoke ok"
