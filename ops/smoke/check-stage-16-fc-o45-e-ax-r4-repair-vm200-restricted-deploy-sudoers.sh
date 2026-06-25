#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ax-r4-repair-vm200-restricted-deploy-sudoers.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AX-R4" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AX_INSTALL_VM200_TAILSCALE_RESTRICTED_STATIC_DEPLOY_ACCESS" "$DOC"
grep -Fq "Defaults:apcdeploy !requiretty" "$DOC"
grep -Fq "apcdeploy ALL=(root) NOPASSWD" "$DOC"
grep -Fq "visudo -cf" "$DOC"
grep -Fq "forced_command_probe=PASS" "$DOC"
grep -Fq "AX_R4_RESTRICTED_ACCESS_READY_FOR_AY" "$DOC"
grep -Fq "cat package.tgz | ssh apcdeploy@website-edge" "$DOC"
grep -Fq "NO public \`/var/www\` static deploy" "$DOC"
grep -Fq "NO sshd config mutation" "$DOC"
grep -Fq "AY should not use QGA for package transfer" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AX-R4 restricted deploy sudoers repair smoke"
