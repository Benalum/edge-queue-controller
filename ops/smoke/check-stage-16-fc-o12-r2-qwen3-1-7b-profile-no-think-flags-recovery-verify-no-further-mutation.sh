#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o12-r2-qwen3-1-7b-profile-no-think-flags-recovery-verify-no-further-mutation.md"

python3 - <<'PY_SMOKE'
from pathlib import Path
import re
import sys

doc = Path("docs/stage-16-fc-o12-r2-qwen3-1-7b-profile-no-think-flags-recovery-verify-no-further-mutation.md")
text = doc.read_text()

required = [
    "Stage 16 FC-O12-R2 qwen3:1.7b no-think flags recovery verify no further mutation",
    "APPROVE_STAGE_16_FC_O12_QWEN3_1_7B_PROFILE_NO_THINK_FLAGS_ONLY_NO_RUNTIME_NO_JOB_RESET",
    "Base HEAD/origin/main: `4fd88c4`",
    "FC-O12 successfully mutated the qwen3:1.7b profile",
    "FC-O12-R2C is repo-only finalization using the already-verified values.",
    "profile_sha_before_fc_o12=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf",
    "profile_sha_current_fc_o12_r2b=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899",
    "profile_backup_sha_fc_o12_r2b=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf",
    "qwen3_1_7b_profile_id_fc_o12_r2b=qwen3_1_7b_candidate",
    "qwen3_1_7b_cli_flags_before_fc_o12_r2b=",
    "qwen3_1_7b_cli_flags_after_fc_o12_r2b=--think=false,--hidethinking",
    "qwen3_1_7b_command_has_think_false_fc_o12_r2b=true",
    "qwen3_1_7b_command_has_hidethinking_fc_o12_r2b=true",
    "qwen3_1_7b_command_has_bad_think_syntax_fc_o12_r2b=false",
    "qwen3_1_7b_build_command_after_fc_o12_r2b=docker exec ollama ollama run --think=false --hidethinking qwen3:1.7b PROMPT",
    "ct101_profile_verify_fc_o12_r2b_acceptance_pass=true",
    "Gemma4, gemma3, and llama3.2 profile entries were verified unchanged",
    "active_exact_services_fc_o12_r2b=0",
    "active_general_services_fc_o12_r2b=0",
    "failed_general_units_fc_o12_r2b=6",
    "job105_status_fc_o12_r2b=running",
    "job106_status_fc_o12_r2b=queued",
    "jobs106_111_remain_queued_attempts0_rows0=true",
    "job112_status_fc_o12_r2b=completed",
    "job112_result_rows_fc_o12_r2b=1",
    "ct203_fc_o12_r2b_read_only_acceptance_pass=true",
    "This still does not prove clean qwen3 output after the profile change.",
    "Do not run job106 yet.",
    "fresh qwen3:1.7b summary hygiene proof job only",
]
missing = [s for s in required if s not in text]
if missing:
    print("missing required doc snippets:")
    for m in missing:
        print(f"  - {m}")
    sys.exit(1)

patterns = {
    "raw Tailscale IPv4": r"100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}",
    "raw private 10 IPv4": r"10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}",
    "raw private 192 IPv4": r"192\.168\.[0-9]{1,3}\.[0-9]{1,3}",
    "raw Tailscale IPv6": r"fd7a:[0-9a-f:]+",
}
for label, pattern in patterns.items():
    if re.search(pattern, text):
        print(f"{label} leaked into doc")
        sys.exit(1)

print("stage-16-fc-o12-r2c qwen3 no-think flags repo-only smoke passed")
PY_SMOKE
