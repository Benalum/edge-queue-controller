#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o15-ollama-concurrency-discovery-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O15 Ollama concurrency discovery no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`018eb2e\`" "$DOC"
grep -Fq "This stage is read-only against CT101 and CT203." "$DOC"

grep -Fq "FC-O14 proved qwen3:1.7b summary output hygiene" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL=" "$DOC"
grep -Fq "OLLAMA_MAX_LOADED_MODELS=" "$DOC"
grep -Fq "OLLAMA_MAX_QUEUE=" "$DOC"
grep -Fq "OLLAMA_CONTEXT_LENGTH=" "$DOC"

grep -Fq "quick_check_fc_o15=ok" "$DOC"
grep -Fq "job106_status_fc_o15=queued" "$DOC"
grep -Fq "job113_status_fc_o15=completed" "$DOC"
grep -Fq "ct203_fc_o15_read_only_acceptance_pass=true" "$DOC"

grep -Fq "profile_sha_fc_o15=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o15=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "active_exact_services_fc_o15=0" "$DOC"
grep -Fq "active_general_services_fc_o15=0" "$DOC"
grep -Fq "ct101_fc_o15_read_only_acceptance_pass=true" "$DOC"

grep -Fq "CT203 is the durable queue and claim authority." "$DOC"
grep -Fq "Do not let Ollama become the durable job queue." "$DOC"
grep -Fq "Run job106 only as a qwen3 JSON one-shot" "$DOC"

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

echo "stage-16-fc-o15 ollama concurrency discovery smoke passed"
