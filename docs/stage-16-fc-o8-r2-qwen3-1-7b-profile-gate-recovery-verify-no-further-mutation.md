# Stage 16 FC-O8-R2 qwen3:1.7b profile gate recovery verify no further mutation

Date: 2026-06-23

## Approval

Approval phrase used for the profile mutation in FC-O8:

    APPROVE_STAGE_16_FC_O8_QWEN3_1_7B_PROFILE_PROVEN_GATE_ONLY_NO_RUNTIME_NO_JOB_RESET

## Recovery note

FC-O8 successfully mutated the CT101 profile, then failed during the CT203 post-check due to a heredoc close error before the repo documentation checkpoint was committed.

FC-O8-R2 performs verification only. It does not mutate the profile further.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O7.
- Base HEAD/origin/main: `7641d58`.
- Base tag: `controller-stage-16-fc-o7-proven-profile-gate-diagnosis-no-apply-2026-06-23`.

## Mutation boundary

This recovery stage is read-only against CT101 and CT203.

It did not:

- mutate CT101 profile further,
- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- reset job105,
- process jobs,
- change gemma4, gemma3, or llama3.2 proven/profile-gate state,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- call Ollama endpoints,
- pull models,
- restart CTs or VMs.

## Verified profile state

    profile_path=/etc/edge-ct101-worker/model-profiles.yaml
    profile_sha_before_fc_o8=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    profile_sha_current_fc_o8_r2=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf
    profile_backup_path_fc_o8_r2=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o8-pre-qwen3-gate.20260623T154924Z.bak
    profile_backup_sha_fc_o8_r2=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    worker_sha_fc_o8_r2=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    worker_load_profiles_after_fc_o8_r2=true
    worker_loaded_profile_count_after_fc_o8_r2=6

## qwen3:1.7b gate change verified

    qwen3_1_7b_profile_id_fc_o8_r2=qwen3_1_7b_candidate
    qwen3_1_7b_policy_before_fc_o8_r2=no_default_until_proven
    qwen3_1_7b_policy_after_fc_o8_r2=exact_marker_only
    qwen3_1_7b_allowed_types_after_fc_o8_r2=future_single_model_probe_only,stage16_fc_summary_semantic_probe,stage16_fc_json_semantic_probe

Gemma4, gemma3, and llama3.2 profile entries were verified unchanged relative to the FC-O8 pre-mutation backup.

## CT101 default-off posture

    active_exact_services_fc_o8_r2=0
    active_exact_timers_fc_o8_r2=0
    active_general_services_fc_o8_r2=0
    active_general_timers_fc_o8_r2=0
    failed_general_units_fc_o8_r2=6
    ct101_default_off_fc_o8_r2_acceptance_pass=true

## CT203 state unchanged

    quick_check_fc_o8_r2=ok
    job105_status_fc_o8_r2=running
    job105_attempts_fc_o8_r2=1
    job105_result_rows_fc_o8_r2=0
    jobs106_111_remain_queued_attempts0_rows0=true
    ct203_fc_o8_r2_read_only_acceptance_pass=true

## Decision

The qwen3:1.7b profile no longer uses the no-default-until-proven refusal policy.

This still does not prove qwen3:1.7b model generation.

Do not run jobs106-111 yet.

Do not retry job105 blindly.

Preferred next stage is a no-apply decision between:

1. insert a fresh qwen3 summary replacement job for a clean post-FC-O8 proof, or
2. explicitly retry/recover job105 with preserved evidence notes.
