# Stage 16 FC-O3-R4 CT101 profile apply verified no further mutation

Date: 2026-06-22

## Base checkpoint

- Prior completed repo checkpoint: Stage 16 FC-O2.
- Base HEAD/origin/main: `0104e84`.
- Base tag: `controller-stage-16-fc-o2-profile-gate-root-cause-remediation-plan-no-apply-2026-06-22`.

## Recovery reason

FC-O3-R2 successfully wrote the CT101 profile file, then failed during worker import validation because the ad-hoc importlib validation did not register the dataclass-decorated worker module in `sys.modules`.

FC-O3-R3 then failed before verification because the read-only verifier reused an escaped f-string shell quoting pattern.

FC-O3-R4 fixes the verification harness and performs read-only verification only.

## Mutation boundary

This stage is read-only against CT101 and CT203.

It did not mutate CT101 profile, write CT203 DB, insert/reset/delete/retry jobs, process jobs, start/stop/restart/reload/enable/disable/reset-failed services, clear failed unit evidence, call Ollama endpoints, pull models, mutate Docker, activate scheduler, or enable persistent workers.

## Verified profile state

    profile_sha_expected_before_fc_o3_r4=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    profile_sha_current_fc_o3_r4=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    profile_backup_path_fc_o3_r4=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o3-r2-pre-profile-gate.20260623T050325Z.bak
    profile_backup_sha_fc_o3_r4=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c
    worker_sha_fc_o3_r4=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    worker_load_profiles_after_fc_o3_r4=true
    worker_loaded_profile_count_after_fc_o3_r4=6

## Verified profile gates

    qwen3_1_7b_allows=stage16_fc_summary_semantic_probe,stage16_fc_json_semantic_probe
    gemma4_e4b_allows=stage16_fc_companion_chat_semantic_probe,stage16_fc_study_tutor_semantic_probe,stage16_fc_flashcards_semantic_probe
    gemma3_4b_allows=stage16_fc_companion_chat_semantic_probe
    llama3_2_3b_allows=stage16_fc_safe_refusal_semantic_probe

## CT203 state unchanged

    quick_check_fc_o3_r4=ok
    ct203_fc_o3_r4_read_only_acceptance_pass=true
    jobs95_99_completed_fc_o3_r4=3
    jobs95_99_running_fc_o3_r4=2
    jobs95_99_result_rows_fc_o3_r4=3
    jobs100_104_queued_fc_o3_r4=2
    jobs100_104_running_fc_o3_r4=3
    jobs100_104_completed_fc_o3_r4=0
    jobs100_104_failed_fc_o3_r4=0
    jobs100_104_result_rows_fc_o3_r4=0

## Runtime posture unchanged

    active_exact_services_fc_o3_r4=0
    active_exact_timers_fc_o3_r4=0
    active_general_services_fc_o3_r4=0
    active_general_timers_fc_o3_r4=0
    failed_general_units_fc_o3_r4=5

## Decision

The FC-O3 profile gate remediation is applied and verified.

Do not reuse stale jobs97, 99, 100, 101, or 104.

Do not clear failed unit evidence.

Do not run jobs102 or 103.

Preferred next stage is a no-apply replacement-job contract for clean post-profile probes with new job IDs.
