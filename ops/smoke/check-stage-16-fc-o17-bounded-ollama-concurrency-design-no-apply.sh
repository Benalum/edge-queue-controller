#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o17-bounded-ollama-concurrency-design-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O17 bounded Ollama concurrency design no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`65732c9\`" "$DOC"
grep -Fq "This stage is repo documentation and smoke only." "$DOC"

grep -Fq "job106_strict_json_pass_fc_o16=true" "$DOC"
grep -Fq "qwen3:1.7b is now a viable small model candidate" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL=1" "$DOC"
grep -Fq "OLLAMA_MAX_LOADED_MODELS=<unset>" "$DOC"
grep -Fq "OLLAMA_MAX_QUEUE=<unset>" "$DOC"
grep -Fq "CT101 memory=31Gi total, 29Gi available" "$DOC"

grep -Fq "CT203 must remain the durable queue and claim authority." "$DOC"
grep -Fq "Ollama should not become the durable job queue." "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL=2" "$DOC"
grep -Fq "Pattern A is recommended first." "$DOC"
grep -Fq "Do not mutate concurrency yet." "$DOC"
grep -Fq "without enabling persistent workers or bulk queue draining" "$DOC"

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw Tailscale IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq 'fd7a:[0-9a-f:]+' "$DOC"; then
  echo "raw Tailscale IPv6 leaked into doc"
  exit 1
fi

echo "stage-16-fc-o17 bounded ollama concurrency design smoke passed"
