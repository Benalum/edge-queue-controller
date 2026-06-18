#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-ll-deploy-lj-current-pvew-status-model-to-ct203.md"

test -f "$DOC"
python3 -m py_compile edge_controller.py

grep -Fq "STAGE_14J_LJ_CURRENT_PVEW_STATUS_MODEL_V1" edge_controller.py
grep -Fq '"schema_version": 2' edge_controller.py
grep -Fq '"id": "pvew"' edge_controller.py
grep -Fq '"id": "vm-200"' edge_controller.py
grep -Fq '"id": "ct-203"' edge_controller.py
grep -Fq '"id": "ct-204"' edge_controller.py

grep -Fq "APPROVE_PHASE_14J_LL_DEPLOY_LJ_CURRENT_PVEW_STATUS_MODEL_TO_CT203_AND_RESTART_CONTROLLER_NO_DB_MUTATION_NO_STORAGE_MUTATION_NO_CT_VM_CONFIG_NO_CLOUDFLARE" "$DOC"
grep -Fq "8a5733b18d2807be9aaa55403929a30cb85182ca34316d1bdb0901d4b07f61e1" "$DOC"
grep -Fq "026a7dfe0fa7e04969f0bb5343e090e99c5454b03136fb753fc379cba148c24b" "$DOC"
grep -Fq "/opt/edge-queue-controller/current/edge_controller.py.bak-phase-14j-ll-20260618T194849Z" "$DOC"
grep -Fq "overall_state: online" "$DOC"
grep -Fq "nodes: ct-203,pvew,vm-200,ct-204" "$DOC"
grep -Fq "normalized.schema_version: 2" "$DOC"
grep -Fq "DB integrity: \`ok\`" "$DOC"
grep -Fq "No DB mutation." "$DOC"
grep -Fq "No storage mutation." "$DOC"
grep -Fq "No Cloudflare, DNS, or tunnel mutation." "$DOC"

echo "PASS check-phase-14j-ll-deploy-lj-current-pvew-status-model-to-ct203"
