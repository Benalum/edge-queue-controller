#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o4-post-profile-replacement-job-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O4 post-profile replacement job contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`c3a6c08\`" "$DOC"
grep -Fq "This stage is no-apply." "$DOC"

grep -Fq "fc_o3_r4_doc_verified_for_o4=true" "$DOC"
grep -Fq "quick_check_fc_o4=ok" "$DOC"
grep -Fq "ct203_fc_o4_read_only_acceptance_pass=true" "$DOC"
grep -Fq "profile_sha_fc_o4=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec" "$DOC"
grep -Fq "ct101_fc_o4_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Do not reuse these stale/evidence jobs:" "$DOC"
grep -Fq "| 97 | qwen3:1.7b | summary | running/stale, failed CT101 unit |" "$DOC"
grep -Fq "| 104 | llama3.2:3b | safe_refusal | running/stale, failed CT101 unit |" "$DOC"
grep -Fq "Do not run old queued jobs102 or 103." "$DOC"

grep -Fq "insert exactly seven fresh post-profile replacement jobs" "$DOC"
grep -Fq "stage16_fc_summary_semantic_probe | qwen3:1.7b" "$DOC"
grep -Fq "stage16_fc_json_semantic_probe | qwen3:1.7b" "$DOC"
grep -Fq "stage16_fc_companion_chat_semantic_probe | gemma4:e4b" "$DOC"
grep -Fq "stage16_fc_companion_chat_semantic_probe | gemma3:4b" "$DOC"
grep -Fq "stage16_fc_study_tutor_semantic_probe | gemma4:e4b" "$DOC"
grep -Fq "stage16_fc_flashcards_semantic_probe | gemma4:e4b" "$DOC"
grep -Fq "stage16_fc_safe_refusal_semantic_probe | llama3.2:3b" "$DOC"

grep -Fq "backup CT203 DB before insert" "$DOC"
grep -Fq "not reset or mutate old jobs97, 99, 100, 101, 102, 103, or 104" "$DOC"
grep -Fq "not run jobs" "$DOC"
grep -Fq "Post-insert runtime must be separate from DB insertion." "$DOC"
grep -Fq "Proceed next to a separately approved DB insert stage for replacement jobs only." "$DOC"

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
if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in no-apply FC-O4 doc"
  exit 1
fi

echo "stage-16-fc-o4 post-profile replacement job contract smoke passed"
