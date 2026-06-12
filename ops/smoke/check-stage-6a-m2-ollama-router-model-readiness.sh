#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-6a-m2-ollama-router-model-readiness.md"
TARGET="${EDGE_PROXMOX_SSH_TARGET:-root@100.88.194.19}"
VMID="${EDGE_LLMS_CT_VMID:-101}"
OLLAMA_URL="${EDGE_OLLAMA_URL:-http://100.88.245.33:11434}"

echo "=== Stage 6A-M2 smoke: Ollama router model readiness ==="

test -f "$DOC"

grep -q "Stage 6A-M2 Ollama Router Model Readiness" "$DOC"
grep -q "tiny_intent_classifier -> qwen3:0.6b" "$DOC"
grep -q "tiny_intent_classifier_fallback -> qwen3:1.7b" "$DOC"
grep -q "default_small_chat -> llama3.2:3b" "$DOC"
grep -q "multilingual_companion -> gemma3:4b" "$DOC"
grep -q "larger_local_reasoning -> gemma4:e4b" "$DOC"
grep -q "qwen2.5-coder:7b was attempted but failed with a digest mismatch" "$DOC"
grep -q "no app runtime behavior is changed" "$DOC"

echo
echo "=== verify models on CT${VMID} ==="
ssh "$TARGET" "pct exec ${VMID} -- bash -lc '
set -euo pipefail

docker exec ollama ollama list | tee /tmp/stage-6a-m2-ollama-list.txt

grep -q \"qwen3:0.6b\" /tmp/stage-6a-m2-ollama-list.txt
grep -q \"qwen3:1.7b\" /tmp/stage-6a-m2-ollama-list.txt
grep -q \"llama3.2:3b\" /tmp/stage-6a-m2-ollama-list.txt
grep -q \"gemma3:4b\" /tmp/stage-6a-m2-ollama-list.txt
grep -q \"gemma4:e4b\" /tmp/stage-6a-m2-ollama-list.txt
'"

echo
echo "=== verify Ollama API responds ==="
ssh "$TARGET" "pct exec ${VMID} -- bash -lc '
set -euo pipefail
curl -fsS ${OLLAMA_URL}/api/tags >/tmp/stage-6a-m2-tags.json
grep -q \"qwen3:0.6b\" /tmp/stage-6a-m2-tags.json
grep -q \"qwen3:1.7b\" /tmp/stage-6a-m2-tags.json
grep -q \"llama3.2:3b\" /tmp/stage-6a-m2-tags.json
grep -q \"gemma3:4b\" /tmp/stage-6a-m2-tags.json
'"

echo
echo "=== lightweight generate smoke ==="
ssh "$TARGET" "pct exec ${VMID} -- bash -lc '
set -euo pipefail

for model in qwen3:0.6b qwen3:1.7b llama3.2:3b gemma3:4b; do
  echo \"--- API testing \$model ---\"
  timeout 120 curl -fsS \
    -H \"Content-Type: application/json\" \
    -X POST ${OLLAMA_URL}/api/generate \
    -d \"{\\\"model\\\":\\\"\$model\\\",\\\"prompt\\\":\\\"Reply with the word OK.\\\",\\\"stream\\\":false,\\\"options\\\":{\\\"num_predict\\\":16}}\" \
    >/tmp/stage-6a-m2-generate.json

  grep -q \"response\" /tmp/stage-6a-m2-generate.json
done
'"

echo
echo "PASS: Stage 6A-M2 Ollama router model readiness is documented and verified."
