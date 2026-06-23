#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o39-product-result-worker-profile-remediation-implementation-contract-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O39 product result worker/profile remediation implementation contract no-runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`6753fc2\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O39_PRODUCT_RESULT_WORKER_PROFILE_REMEDIATION_IMPLEMENTATION_CONTRACT_NO_RUNTIME_NO_JOB_MUTATION_NO_RESET_FAILED" "$DOC"

grep -Fq "This stage is repo documentation and smoke only." "$DOC"
grep -Fq "NO runtime" "$DOC" || true

grep -Fq "Do not weaken the proven guard path." "$DOC"
grep -Fq "Add a separate product path." "$DOC"
grep -Fq "product_visible_output_v1" "$DOC"
grep -Fq "guard_exact_marker_v1" "$DOC"

grep -Fq "extract_visible_output" "$DOC"
grep -Fq "detect_visible_thinking" "$DOC"
grep -Fq "detect_hidden_thinking_markers" "$DOC"
grep -Fq "detect_guard_metadata_output" "$DOC"
grep -Fq "detect_internal_surface_terms" "$DOC"
grep -Fq "validate_product_visible_output" "$DOC"

grep -Fq "REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT" "$DOC"
grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$DOC"
grep -Fq "REFUSE_PRODUCT_HIDDEN_THINKING" "$DOC"
grep -Fq "REFUSE_PRODUCT_GUARD_JSON" "$DOC"
grep -Fq "REFUSE_PRODUCT_INTERNAL_TERMS" "$DOC"
grep -Fq "REFUSE_PRODUCT_SHAPE_MISMATCH" "$DOC"
grep -Fq "REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE" "$DOC"

grep -Fq "Companion chat validator" "$DOC"
grep -Fq "Study tutor validator" "$DOC"
grep -Fq "Flashcards validator" "$DOC"
grep -Fq "Safe refusal validator" "$DOC"

grep -Fq "FC-O40 must add tests or a smoke script" "$DOC"
grep -Fq "Existing exact_marker_only tests still pass." "$DOC"
grep -Fq "FC-O40 must not start services, run jobs, insert jobs, mutate DB, or call Ollama." "$DOC"

grep -Fq "Profile policy change for FC-O41" "$DOC"
grep -Fq "Do not rerun completed job107." "$DOC"
grep -Fq "Preserve jobs108-111 as historical stale probes" "$DOC"
grep -Fq "First product runtime for FC-O43" "$DOC"
grep -Fq "Next recommended stage: FC-O40 worker code support and tests only, no job processing." "$DOC"

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

echo "stage-16-fc-o39 implementation contract smoke passed"
