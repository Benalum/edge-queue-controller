#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-aw-vm200-tailscale-restricted-deploy-access-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AW" "$DOC"
grep -Fq "Tailscale Restricted Deploy Access Contract" "$DOC"
grep -Fq "QEMU guest-agent file transfer is the wrong long-term path" "$DOC"
grep -Fq "Tailscale-first inter-system communication" "$DOC"
grep -Fq "apc-vm200-static-deploy-wrapper-ui" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AX_INSTALL_VM200_TAILSCALE_RESTRICTED_STATIC_DEPLOY_ACCESS" "$DOC"
grep -Fq "AY should not use QGA for package transfer" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "NO key install" "$DOC"
grep -Fq "NO \`authorized_keys\` mutation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AW VM200 Tailscale restricted deploy access contract smoke"
