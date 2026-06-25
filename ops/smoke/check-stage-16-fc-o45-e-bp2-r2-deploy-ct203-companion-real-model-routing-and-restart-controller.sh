#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bp2-r2-deploy-ct203-companion-real-model-routing-and-restart-controller.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BP2-R2" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BP2_DEPLOY_CT203_COMPANION_REAL_MODEL_ROUTING_AND_RESTART_CONTROLLER" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "mock/no-model" "$DOC"
grep -Fq "BP2_R2_CT203_DEPLOY_RESTART_RECORDED=PASS" "$DOC"
grep -Fq "BP2_R2_DEPLOY_RESTART_RECORDED=PASS" "$DOC"
grep -Fq "ct203_controller_restart=PASS" "$DOC"
grep -Fq "controller_service_after=active" "$DOC"
grep -Fq "_CHAT_QUEUED_REAL_MODEL" "$DOC"
grep -Fq "EDGE_COMPANION_CHAT_REQUESTED_MODEL" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BP2-R2 deploy CT203 Companion real-model routing and restart controller smoke"
