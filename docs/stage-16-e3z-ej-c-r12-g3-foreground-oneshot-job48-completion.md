# Stage 16 E3Z-EJ-C-R12-G3 Foreground One-Shot Job 48 Completion

Date: 2026-06-22

## Result

Stage 16 E3Z-EJ-C-R12-G3 completed the repaired repeat proof for existing job 48.

Final proof marker:

    E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK

Final proof result:

    R12_G3_RESULT=job48_completed_by_foreground_oneshot
    R12_H_RESULT=job48_completion_final_baseline_clean

## Repository checkpoint before this documentation

    HEAD/origin/main=c5e38ac
    previous_tag=controller-stage-16-e3z-ej-c-r10-exact-mismatch-diagnostic-read-only-2026-06-22
    repo_status=clean

## R11 repair summary

R11 safely repaired only job 48 after R10 diagnosed an exact-marker mismatch caused by the previous prompt shape.

R11 pre-state:

    job47 status=completed attempts=1 result_rows=1
    job48 status=running attempts=3 result_rows=0
    job48_old_prompt_sha=7b2fba8c760ec59a8063ccc3c730077cf2908257ed6f2b3a136b0e317909df6d

R11 post-state:

    job48 status=queued
    job48 attempts=3
    job48 result_rows=0
    job48_prompt=Return exactly this text and nothing else: E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
    job48_prompt_sha=33b10c8cc944f6a1b29ae7f50fdf0aa9e780da8c3c4324f34cb70c0a5238c598

R11 backup:

    /var/lib/edge-queue-controller/stage16-r11-backups/edge_queue.sqlite3.stage16-e3z-ej-c-r11-pre-job48-reset.20260622T233221Z.bak
    sha256=9de09188b0419e24e48d7cc36d7913fac839554dd2780ebb082176af41c72b0c
    size_bytes=43819008

## R12 discovery summary

R12 confirmed the authoritative CT203 database and safe CT101 worker path:

    CT203 authoritative DB=/var/lib/edge-queue-controller/edge_queue.sqlite3
    PVESO reachable through PVEW
    CT101 status=running
    worker=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    worker_sha256=69f64e83b58553bfec5c413381b055c21b8be6d167378e0bbff05a8f1857e50f
    profile_file=/etc/edge-ct101-worker/model-profiles.yaml
    profile_sha256=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
    profile_id=qwen25_router_small
    model_name=qwen2.5:0.5b
    completion_validation_policy=exact_marker_only

The systemd service was intentionally not started. R12-G3 used foreground one-shot mode:

    /usr/bin/python3 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py --once --job-id 48

CT101 service posture before and after R12-G3:

    edge-ct101-ollama-worker.service active=inactive enabled=disabled
    ai-platform-laptop-queue-worker.service active=inactive enabled=masked
    ai-platform-laptop-queue-worker@model-tiny.service active=inactive enabled=masked
    ai-platform-laptop-queue-worker@model-small.service active=inactive enabled=masked

## R12-G3 execution

R12-G3 pre-state:

    pre_quick_check=ok
    pre_job47 status=completed attempts=1 result_rows=1
    pre_job48 status=queued attempts=3 result_rows=0
    pre_job48_prompt_sha=33b10c8cc944f6a1b29ae7f50fdf0aa9e780da8c3c4324f34cb70c0a5238c598

R12-G3 backup:

    /var/lib/edge-queue-controller/stage16-r12-backups/edge_queue.sqlite3.stage16-e3z-ej-c-r12-g3-pre-job48-oneshot.20260622T234404Z.bak
    sha256=89cbc105f62c4b2c613028b1770a51a322c0b6174bb5bc9b9e3c3180d51f9dc5
    size_bytes=43819008

R12-G3 foreground worker result:

    foreground_worker_rc=0
    R12_G3_RESULT=job48_completed_by_foreground_oneshot

R12-G3 post-state:

    post_quick_check=ok
    post_job47 status=completed attempts=1 result_rows=1
    post_job48 status=completed attempts=4 result_rows=1
    post_job48_last_error=None
    post_job48_forwarded_at=None

Job 48 result row:

    job_id=48
    model=qwen2.5:0.5b
    error=None
    created_at=2026-06-22T23:44:07.531586Z
    updated_at=2026-06-22T23:44:07.531586Z
    response_text=E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
    response_text_sha256=a567b6299a152552cee2aae209616c8d708bd47cd1aa02b8bd93194503818382
    response_exact_expected_marker=True

## R12-H final baseline

R12-H final read-only baseline confirmed:

    quick_check=ok
    jobs_total=47
    max_job_id=48
    job37_result_rows=1
    job38_result_rows=1
    job39_result_rows=1
    job40_result_rows=1
    job41_result_rows=1
    job42_result_rows=1
    job43_result_rows=1
    job44_result_rows=1
    job45_result_rows=1
    job46_result_rows=1
    job47_result_rows=1
    job48_result_rows=1

Final job 48 state:

    job48 status=completed
    job48 attempts=4
    job48 requested_model=qwen2.5:0.5b
    job48 job_type=stage16_e3z_limited_persistent_worker_repeat_proof
    job48 last_error=None
    job48 forwarded_at=None
    job48 updated_at=2026-06-22T23:44:07.531586Z
    job48_result_error=None
    job48_response_sha256=a567b6299a152552cee2aae209616c8d708bd47cd1aa02b8bd93194503818382
    job48_response_exact_expected_marker=True

## Safety boundary

R12-G3 intentionally did not perform these actions:

    NO service start/stop/restart/reload/enable/disable
    NO timer activation
    NO scheduler activation
    NO worker service start
    NO persistent loop service
    NO job insert
    NO mutation to jobs 37-47
    NO mutation to jobs other than id=48
    NO CT/VM start/stop/restart
    NO Docker start/stop/restart
    NO secrets printed

Allowed and completed actions were limited to:

    one CT203 SQLite pre-attempt backup
    one foreground CT101 worker invocation
    one claim attempt for existing jobs.id=48 only
    one qwen2.5:0.5b Ollama CLI model call through approved worker/profile
    completion of jobs.id=48 with one job_results row only because exact marker validation passed

## Conclusion

Stage 16 E3Z-EJ-C-R12-G3 proves the repaired compact prompt can complete the repeat limited persistent CT101 worker proof through a bounded foreground one-shot worker path. The prior R10 failure was repaired by R11 prompt shortening to match the known-good exact-output pattern, and R12-G3 completed job 48 with the expected exact marker.
