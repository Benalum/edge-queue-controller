#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-av-r3-vm200-access-method-discovery.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AV-R3" "$DOC"
grep -Fq "VM200 Access Method Discovery" "$DOC"
grep -Fq "AV-R2 fixed the package upload pattern" "$DOC"
grep -Fq "REFUSE_VM200_SSH_UNREACHABLE_FROM_PVEW" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "NO package copy to VM200" "$DOC"
grep -Fq "QEMU guest agent" "$DOC"
grep -Fq "corrected VM200 SSH" "$DOC"
grep -Fq "FC-O45-E-AV-R4" "$DOC"
grep -Fq "Live discovery output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AV-R3 VM200 access method discovery doc smoke"
