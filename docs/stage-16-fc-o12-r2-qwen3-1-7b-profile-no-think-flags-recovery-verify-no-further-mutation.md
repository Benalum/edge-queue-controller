# Stage 16 FC-O12-R2 qwen3:1.7b no-think flags recovery verify no further mutation

Date: 2026-06-23

## Approval

Approval phrase used for the FC-O12 profile mutation:

    APPROVE_STAGE_16_FC_O12_QWEN3_1_7B_PROFILE_NO_THINK_FLAGS_ONLY_NO_RUNTIME_NO_JOB_RESET

## Recovery note

FC-O12 successfully mutated the qwen3:1.7b profile, then failed only because the verification searched loaded profiles with the wrong returned structure.

FC-O12-R2 verified the profile, command, CT101 default-off posture, and CT203 unchanged queue state. FC-O12-R2B then failed only because the focused smoke looked for a string that the generated doc did not contain exactly.

FC-O12-R2C is repo-only finalization using the already-verified values. It performs no infrastructure or database reads or writes.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O11.
- Base HEAD/origin/main: `4fd88c4`.
- Base tag: `controller-stage-16-fc-o11-qwen3-response-hygiene-diagnosis-no-apply-2026-06-23`.

## Mutation boundary

This recovery stage is repo docs/smoke/commit/tag/push only.

It did not mutate CT101 profile further, change worker code, write CT203 DB, insert/reset/delete/retry/manually complete jobs, reset job105, run job106, process jobs106-111, retry job112, mutate gemma4/gemma3/llama3.2 profile entries, start/stop/restart/reload/enable/disable/reset-failed services, clear failed unit evidence, write systemd units, run daemon-reload, activate scheduler, enable persistent workers, mutate Docker, call Ollama endpoints, pull models, or restart CTs/VMs.

## Verified profile state

    profile_path=/etc/edge-ct101-worker/model-profiles.yaml
    profile_sha_before_fc_o12=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf
    profile_sha_current_fc_o12_r2=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    profile_sha_current_fc_o12_r2b=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    profile_backup_path_fc_o12_r2b=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o12-pre-qwen3-1-7b-cli-flags.20260623T161214Z.bak
    profile_backup_sha_fc_o12_r2b=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf
    worker_sha_fc_o12_r2b=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    worker_loaded_object_type_fc_o12_r2b=dict
    worker_load_profiles_after_fc_o12_r2b=true
    worker_loaded_profile_count_after_fc_o12_r2b=6

## qwen3:1.7b hygiene change verified

    qwen3_1_7b_profile_id_fc_o12_r2b=qwen3_1_7b_candidate
    qwen3_1_7b_cli_flags_before_fc_o12_r2b=
    qwen3_1_7b_cli_flags_after_fc_o12_r2b=--think=false,--hidethinking
    qwen3_1_7b_policy_after_fc_o12_r2b=exact_marker_only
    qwen3_1_7b_allowed_types_after_fc_o12_r2b=future_single_model_probe_only,stage16_fc_summary_semantic_probe,stage16_fc_json_semantic_probe
    qwen3_1_7b_build_command_after_fc_o12_r2b=docker exec ollama ollama run --think=false --hidethinking qwen3:1.7b PROMPT
    qwen3_1_7b_command_has_think_false_fc_o12_r2b=true
    qwen3_1_7b_command_has_hidethinking_fc_o12_r2b=true
    qwen3_1_7b_command_has_bad_think_syntax_fc_o12_r2b=false
    ct101_profile_verify_fc_o12_r2b_acceptance_pass=true

Gemma4, gemma3, and llama3.2 profile entries were verified unchanged relative to the FC-O12 pre-mutation backup.

## CT101 default-off posture

    active_exact_services_fc_o12_r2b=0
    active_exact_timers_fc_o12_r2b=0
    active_general_services_fc_o12_r2b=0
    active_general_timers_fc_o12_r2b=0
    failed_general_units_fc_o12_r2b=6
    ct101_default_off_fc_o12_r2b_acceptance_pass=true

## CT203 state unchanged

    quick_check_fc_o12_r2b=ok
    job105_status_fc_o12_r2b=running
    job105_attempts_fc_o12_r2b=1
    job105_result_rows_fc_o12_r2b=0
    job106_status_fc_o12_r2b=queued
    job106_attempts_fc_o12_r2b=0
    job106_result_rows_fc_o12_r2b=0
    jobs106_111_remain_queued_attempts0_rows0=true
    job112_status_fc_o12_r2b=completed
    job112_attempts_fc_o12_r2b=1
    job112_result_rows_fc_o12_r2b=1
    ct203_fc_o12_r2b_read_only_acceptance_pass=true

## Decision

The qwen3:1.7b profile now builds an Ollama command containing `--think=false` and `--hidethinking`.

This still does not prove clean qwen3 output after the profile change.

Do not run job106 yet.

The next stage should insert a fresh qwen3:1.7b summary hygiene proof job only, no runtime, no old job mutation. Then run that fresh proof in a separate approved one-shot.
