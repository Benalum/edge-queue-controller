# Stage 16 FC-O5-R2 insert replacement jobs 105-111 only no-runtime

Date: 2026-06-22

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O5_INSERT_REPLACEMENT_JOBS_105_111_ONLY_NO_RUNTIME_NO_OLD_JOB_MUTATION

## Recovery note

A previous pasted block was an old FC-D block. It failed at repo guard before any mutation.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O4.
- Base HEAD/origin/main: `610bc71`.
- Base tag: `controller-stage-16-fc-o4-post-profile-replacement-job-contract-no-apply-2026-06-22`.

## Mutation boundary

This stage mutated only the CT203 DB by inserting seven fresh queued replacement jobs.

It did not:

- reset, delete, retry, or manually complete old jobs,
- mutate jobs97, 99, 100, 101, 102, 103, or 104,
- create job_results rows,
- mutate CT101 profile,
- process jobs,
- start/stop/restart/reload/enable/disable services or timers,
- reset failed units,
- clear evidence,
- call Ollama endpoints,
- pull models,
- mutate Docker,
- activate scheduler,
- enable persistent workers,
- restart CTs or VMs.

## DB backup

    db_backup_path_fc_o5_r2=/var/lib/edge-queue-controller/stage16-fc-backups/edge_queue.sqlite3.stage16-fc-o5-r2-pre-jobs105-111-insert.20260623T153359Z.bak
    db_backup_sha_fc_o5_r2=28767cec9278a9e6302a668e8d560d144888089fdbf24de796560a526d936d5d

## Inserted replacement jobs

| Job | Replaces | Job type | Model | Status | Attempts | Result rows |
|---:|---:|---|---|---|---:|---:|
| 105 | 97 | stage16_fc_summary_semantic_probe | qwen3:1.7b | queued | 0 | 0 |
| 106 | 99 | stage16_fc_json_semantic_probe | qwen3:1.7b | queued | 0 | 0 |
| 107 | 100 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 108 | 101 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | queued | 0 | 0 |
| 109 | 102 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 110 | 103 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | queued | 0 | 0 |
| 111 | 104 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | queued | 0 | 0 |

## Verification

    quick_check_before_fc_o5_r2=ok
    quick_check_after_fc_o5_r2=ok
    inserted_job_ids_fc_o5_r2=105,106,107,108,109,110,111
    jobs105_111_queued_fc_o5_r2=7
    jobs105_111_running_fc_o5_r2=0
    jobs105_111_completed_fc_o5_r2=0
    jobs105_111_failed_fc_o5_r2=0
    jobs105_111_result_rows_fc_o5_r2=0
    max_job_id_after_fc_o5_r2=111
    ct203_fc_o5_r2_insert_acceptance_pass=true

## Old evidence preserved

Jobs97, 99, 100, 101, and 104 remain stale/running evidence rows with zero result rows.

Old jobs102 and 103 remain queued with zero attempts and zero result rows.

No old job was reset or mutated.

## CT101 default-off posture

    profile_sha_fc_o5_r2=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec
    active_exact_services_fc_o5_r2=0
    active_exact_timers_fc_o5_r2=0
    active_general_services_fc_o5_r2=0
    active_general_timers_fc_o5_r2=0
    failed_general_units_fc_o5_r2=5
    ct101_fc_o5_r2_read_only_acceptance_pass=true

## Decision

Replacement jobs 105-111 are now queued.

Do not run them in bulk.

The next stage should run job105 only, with a one-shot general_queue timer, after separate explicit runtime approval.
