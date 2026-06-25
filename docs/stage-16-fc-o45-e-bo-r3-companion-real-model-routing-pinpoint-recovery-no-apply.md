# Stage 16 FC-O45-E-BO-R3 — Companion Real-Model Routing Pinpoint Recovery No-Apply

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `3e6a809`
- Prior readiness tag: `controller-stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only-2026-06-24`
- Failed BO-R2 log: `/home/alex/.project-pilot-bridge/logs/run-1782353470-f00e4b7dc1.log`

## Purpose

BO-R3 recovers the BO-R2 doc/smoke checkpoint.

BO-R2 gathered the needed read-only evidence but failed before commit/tag during the final smoke checkpoint. BO-R3 performs only repo docs/smoke recovery and records the no-apply result.

## Scope

Allowed and performed:

- Write this recovery documentation.
- Write focused smoke.
- Commit/tag/push docs/smoke only.

Explicitly not allowed and not performed:

- NO source patch.
- NO live deploy.
- NO public `/var/www` mutation.
- NO DB write.
- NO job mutation.
- NO result insert.
- NO model/helper/Ollama generation call.
- NO scheduler activation.
- NO timer activation.
- NO persistent worker activation.
- NO backend API deploy.
- NO nginx/cloudflared config mutation.
- NO sshd config mutation.
- NO service restart/reload/start/stop/enable/disable.
- NO CT/VM restart.
- NO storage mutation.
- NO file deletion.

## Pinpoint result

The live UI and Enter-to-send path are working.

The remaining issue is routing/config:

```
live companion.chat jobs are inserted with requested_model=mock/no-model
```

BO-R2 evidence showed:

- Job 568: `companion.chat`, `requested_model=mock/no-model`, `status=queued`, `attempts=0`, no result rows.
- Job 569: `companion.chat`, `requested_model=mock/no-model`, `status=queued`, `attempts=0`, no result rows.
- Companion model/status counts included many queued `mock/no-model` jobs.
- Earlier evidence exists for completed `companion.chat` jobs using `qwen2.5:0.5b`.
- CT101 is reachable.
- Docker is active.
- Ollama container is healthy.
- `qwen2.5:0.5b` is present.
- `edge-ct101-general-queue-worker@.service` exists but is disabled.
- The Ollama worker is inactive.

The BO-R2 source/config grep also exposed the mock queued-chat contract around:

```
_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"
_CHAT_QUEUED_JOB_TYPE = "companion.chat"
decision["requested_model"]
/api/chat/queued
```

## Interpretation

Starting a worker alone is not sufficient.

New Companion jobs must first request a real approved model:

```
qwen2.5:0.5b
```

Then a bounded worker/model proof can claim and complete exactly one job.

## Recommended next phases

```
FC-O45-E-BP — source/config patch so new companion.chat jobs request qwen2.5:0.5b, no runtime activation
FC-O45-E-BQ — bounded one-job Companion model-worker activation proof
```

BQ requires explicit approval because it will claim a job and call the model/helper path.

## Recovery output

```
=== Stage 16 FC-O45-E-BO-R3 Companion real-model routing pinpoint recovery no-apply ===
MUTATION_SCOPE=repo_docs_smoke_commit_tag_push_only
FIX=recover_failed_BO_R2_doc_smoke_checkpoint_after_successful_read_only_evidence
NO source patch
NO live deploy
NO public /var/www mutation
NO DB write
NO job mutation
NO result insert
NO model/helper/Ollama generation call
NO scheduler activation
NO timer activation
NO persistent worker activation
NO backend API deploy
NO nginx/cloudflared config mutation
NO sshd config mutation
NO service restart/reload/start/stop/enable/disable
NO CT/VM restart
NO storage mutation
NO file deletion

=== git dirty-tree preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=3e6a809
head_now=3e6a809
origin_main_now=3e6a809
dirty_status_before:
?? docs/stage-16-fc-o45-e-bo-r2-companion-real-model-routing-source-config-pinpoint-no-apply.md
?? ops/smoke/check-stage-16-fc-o45-e-bo-r2-companion-real-model-routing-source-config-pinpoint-no-apply.sh
dirty_tree_expected_from_failed_BO_R2=PASS

=== previous BO-R2 evidence summary from log ===
prev_log_present=yes
frontend/wrapper-ui/app.js:14434: * - Keep the model label aligned with the proven qwen2.5:0.5b queue-worker path when the old fallback text is rendered.
frontend/wrapper-ui/app.js:14555:        node.textContent = "fallback: qwen2.5:0.5b";
frontend/wrapper-ui/app.js:14556:        node.setAttribute("data-stage16-fc-o45-e-az-model-label", "qwen2.5:0.5b");
frontend/wrapper-ui/app.js:14840:        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
ops/smoke/check-stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.sh:22: grep -F -q "requested_model: mock/no-model" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.sh:22: grep -F -q "requested_model: mock/no-model" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-ac-r2-browser-proof-result-reader-job-125.sh:17: grep -F -q "requested_model: mock/no-model" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-ac-r2-browser-proof-result-reader-job-125.sh:17: grep -F -q "requested_model: mock/no-model" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-af-exact-one-job-model-proof-contract.sh:12: grep -Fq "qwen2.5:0.5b" "$DOC"
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:29: require_text "$CONTRACT" "STAGE16_DEFAULT_MODEL = \"qwen2.5:0.5b\""
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:100: assert contract["model_name"] == "qwen2.5:0.5b"
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:108: good_job = {"job_id": 25, "job_type": "companion.chat", "requested_model": "qwen2.5:0.5b"}
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:100: assert contract["model_name"] == "qwen2.5:0.5b"
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:108: good_job = {"job_id": 25, "job_type": "companion.chat", "requested_model": "qwen2.5:0.5b"}
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:109: bad_job = {"job_id": 24, "job_type": "companion.chat", "requested_model": "mock/no-model"}
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:108: good_job = {"job_id": 25, "job_type": "companion.chat", "requested_model": "qwen2.5:0.5b"}
ops/smoke/check-stage-16-c-default-off-model-worker-contract.sh:109: bad_job = {"job_id": 24, "job_type": "companion.chat", "requested_model": "mock/no-model"}
ops/smoke/check-stage-16-d0-final-model-activation-checklist-no-apply.sh:33: require_text "first small model candidate: qwen2.5:0.5b"
ops/smoke/check-stage-16-fc-o45-e-ad-f-r2-fresh-submit-bridge-proof-job-126.sh:18: grep -F -q "requested_model=mock/no-model" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-ad-f-r2-fresh-submit-bridge-proof-job-126.sh:18: grep -F -q "requested_model=mock/no-model" "$DOC"
ops/smoke/check-stage-15-d-mock-queued-chat-compatibility-apply.sh:28: require_text '_CHAT_QUEUED_MOCK_MODEL = "mock/no-model"'
ops/smoke/check-stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.sh:16: grep -F -q "requested_model: \`mock/no-model\`" "$DOC"
ops/smoke/check-stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.sh:16: grep -F -q "requested_model: \`mock/no-model\`" "$DOC"
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:54: companion.chat jobs are queued with requested_model=mock/no-model
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:176: recent_jobs_json=[{"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id"
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:177: job568_json={"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:178: job569_json={"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:180: companion_jobs_by_requested_model_status_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 439}, {"requeste
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:182: job568_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:183: job569_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:176: recent_jobs_json=[{"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id"
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:177: job568_json={"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:178: job569_json={"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:180: companion_jobs_by_requested_model_status_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 439}, {"requeste
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:182: job568_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:183: job569_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:176: recent_jobs_json=[{"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id"
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:177: job568_json={"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:178: job569_json={"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:180: companion_jobs_by_requested_model_status_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 439}, {"requeste
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:182: job568_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:183: job569_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:176: recent_jobs_json=[{"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id"
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:177: job568_json={"id": 568, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:36:29.420762+00:00", "updated_at": "2026-06-25T01:36:29.420762+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:178: job569_json={"id": 569, "status": "queued", "job_type": "companion.chat", "requested_model": "mock/no-model", "attempts": 0, "last_error": null, "created_at": "2026-06-25T01:43:16.805622+00:00", "updated_at": "2026-06-25T01:43:16.805622+00:00", "user_id": 16}
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:180: companion_jobs_by_requested_model_status_json=[{"requested_model": "mock/no-model", "status": "completed", "n": 3}, {"requested_model": "mock/no-model", "status": "failed", "n": 1}, {"requested_model": "mock/no-model", "status": "queued", "n": 439}, {"requeste
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:182: job568_results_json=[]
docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md:183: job569_results_json=[]
docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md:54: - requested_model: mock/no-model
docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md:54: - requested_model: mock/no-model
docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md:54: - requested_model: mock/no-model
docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md:86: - requested_model=mock/no-model
docs/stage-15-c-mock-queued-chat-endpoint-design-no-apply.md:86: - requested_model=mock/no-model
docs/stage-16-fc-o45-e-ab-f-browser-read-proof-job-125.md:23: - job.requested_model: mock/no-model
docs/stage-16-fc-o45-e-ab-f-browser-read-proof-job-125.md:23: - job.requested_model: mock/no-model
docs/stage-16-fc-o45-e-ab-f-browser-read-proof-job-125.md:23: - job.requested_model: mock/no-model
docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md:22:    - `requested_model: mock/no-model`
docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md:22:    - `requested_model: mock/no-model`
docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md:34: - `requested_model=mock/no-model`
docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md:34: - `requested_model=mock/no-model`
docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md:34: - `requested_model=mock/no-model`
docs/stage-16-e3u-b-read-only-runtime-preflight-result.md:81:     QUEUED_JOB id=24 status=queued attempts=0 job_type='companion.chat' requested_model='mock/no-model'
docs/stage-16-e3u-b-read-only-runtime-preflight-result.md:114:     REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:40: - Used approved small model `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:81: ALLOWED: call an already-installed qwen2.5:0.5b model through bounded PVESO/CT101/Ollama path
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:149: final_verify=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:154: target_final=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:149: final_verify=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:154: target_final=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md:159: FC_O45_E_AG_R3_RUNTIME_PASS target_job_id=127 requested_model=qwen2.5:0.5b marker=FC-O45-E-AG-R3-20260624T230524Z-8728
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:29: - Used already-installed `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:108: ALLOWED: use persona-wrapped qwen2.5:0.5b if already installed
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:172: browser_target_before=id=132,user_id=16,status=queued,job_type=companion.chat,requested_model=mock/no-model,attempts=0,created_at=2026-06-24T23:38:02.199275+00:00,updated_at=2026-06-24T23:38:02.199275+00:00
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:202: final_verify=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:212: target_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ao-browser-job132-queue-worker-e2e.md:219: FC_O45_E_AO_RUNTIME_RECORDED target_job_id=132 requested_model=qwen2.5:0.5b worker_mode=transient_exact_one_queue_worker_e2e creation_method=browser_signed_in_ui_submit_existing_job_id marker=FC-O45-E-AO-20260624T234248Z-10216
docs/stage-16-fc-o45-e-aq-companion-study-tools-endpoint-routing-contract.md:50: - requested_model: `qwen2.5:0.5b`
docs/stage-16-fc-o45-e-ai-companion-persona-wrapper-contract.md:44: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-ai-companion-persona-wrapper-contract.md:103: - use already-installed `qwen2.5:0.5b`,
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:27: - Used already-installed `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:103: ALLOWED: complete only job 131 with persona-wrapped qwen2.5:0.5b
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:167: browser_target_before=id=131,user_id=16,status=queued,job_type=companion.chat,requested_model=mock/no-model,attempts=0,created_at=2026-06-24T23:32:44.758954+00:00,updated_at=2026-06-24T23:32:44.758954+00:00
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:195: final_verify=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:203: target_final=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:195: final_verify=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:203: target_final=id=131,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-an-browser-job131-persona-worker-result.md:210: FC_O45_E_AN_RUNTIME_RECORDED target_job_id=131 requested_model=qwen2.5:0.5b creation_method=browser_signed_in_ui_submit_existing_job_id marker=FC-O45-E-AN-20260624T233607Z-22454
docs/stage-16-e3v-c-read-only-schema-capability-check-result.md:148:     JOB_CLASSIFY id=24 present=true status=queued attempts=0 job_type='companion.chat' requested_model='mock/no-model' result_rows=0
docs/stage-16-e3t-fresh-scheduler-test-job-insert-plan-no-apply.md:22:     job 24 requested_model=mock/no-model
docs/stage-16-e3z-h-r11h-pveso-restricted-model-helper-plan-no-apply.md:53: job_33_model=qwen2.5:0.5b
docs/stage-16-e3z-h-r11h-pveso-restricted-model-helper-plan-no-apply.md:53: job_33_model=qwen2.5:0.5b
docs/stage-16-fc-o45-e-al-submit-to-worker-automation-design-contract.md:46: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-al-submit-to-worker-automation-design-contract.md:46: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-al-submit-to-worker-automation-design-contract.md:70: 5. worker calls already-installed qwen2.5:0.5b
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:24: - Used already-installed `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:71: ALLOWED: call already-installed qwen2.5:0.5b through bounded PVESO/CT101/Ollama path
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:133: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:163: final_verify=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:170: target_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:163: final_verify=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:170: target_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md:177: FC_O45_E_AJ_RUNTIME_RECORDED target_job_id=128 requested_model=qwen2.5:0.5b marker=FC-O45-E-AJ-20260624T231308Z-11260
docs/stage-16-d0-final-model-activation-checklist-no-apply.md:37: - first small model candidate: qwen2.5:0.5b
docs/stage-16-e3t-b-ct203-read-only-insert-preflight-result.md:94:     QUEUED_JOB id=24 status=queued job_type='companion.chat' requested_model='mock/no-model' lane=None
docs/stage-16-fc-o45-e-af-exact-one-job-model-proof-contract.md:40: - Assign an approved small model, preferably `qwen2.5:0.5b`.
docs/stage-16-e3v-repeatable-scheduler-controlled-lane-design-no-apply.md:111:     job 24 rejected because requested_model=mock/no-model is not allowlisted
docs/stage-16-fc-o45-e-ad-f-r2-fresh-submit-bridge-proof-job-126.md:31: - `requested_model=mock/no-model`
docs/stage-16-fc-o45-e-ad-f-r2-fresh-submit-bridge-proof-job-126.md:31: - `requested_model=mock/no-model`
docs/stage-16-fc-o45-e-ah-job127-result-reader-quality-contract.md:56: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-ah-job127-result-reader-quality-contract.md:392: job127_final=id=127,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-c-default-off-model-worker-contract.md:70: qwen2.5:0.5b
docs/stage-15-d-mock-queued-chat-compatibility-apply.md:55: - `requested_model=mock/no-model`
docs/stage-15-d-mock-queued-chat-compatibility-apply.md:55: - `requested_model=mock/no-model`
docs/stage-16-fc-o45-e-ac-r2-browser-proof-result-reader-job-125.md:17: - requested_model: mock/no-model
docs/stage-16-fc-o45-e-ac-r2-browser-proof-result-reader-job-125.md:17: - requested_model: mock/no-model
docs/stage-16-e3s-r2-ct203-read-only-dry-run-result.md:71:     REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:50: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:137: job132_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:137: job132_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:137: job132_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:137: job132_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:137: job132_final=id=132,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:142: (132, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:38:02.199275+00:00', '2026-06-24T23:42:55Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:143: (131, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:32:44.758954+00:00', '2026-06-24T23:36:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:145: (129, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:28:13Z', '2026-06-24T23:28:16Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:146: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:147: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:153: (132, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:154: (131, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:156: (129, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:157: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md:158: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-e3v-k-fresh-eligible-job-insert-plan-no-apply.md:44:     job 24 queued but requested_model=mock/no-model and not allowlisted
docs/stage-16-e3v-d-option-b-atomic-status-claim-implementation-plan-no-apply.md:51:     job 24: queued, attempts=0, requested_model=mock/no-model, result_rows=0
docs/stage-16-e3v-d-option-b-atomic-status-claim-implementation-plan-no-apply.md:305:     job 24 because requested_model=mock/no-model is not allowlisted
docs/stage-16-e3v-e-option-b-wrapper-code-design-no-apply.md:133:     job 24 remains queued but requested_model=mock/no-model is not allowlisted
docs/stage-16-e3t-c-e3s-r4-insert-and-read-only-would-claim-result.md:110:     REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat
docs/stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.md:14: - requested_model: `mock/no-model`
docs/stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.md:14: - requested_model: `mock/no-model`
docs/stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.md:14: - requested_model: `mock/no-model`
docs/stage-16-fc-o45-e-ae-worker-model-readiness-preflight.md:52: 1. Insert or create exactly one `companion.chat` queued job owned by the signed-in test user, with a unique marker and a small approved model such as `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-ae-worker-model-readiness-preflight.md:52: 1. Insert or create exactly one `companion.chat` queued job owned by the signed-in test user, with a unique marker and a small approved model such as `qwen2.5:0.5b`.
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:57: - `requested_model=qwen2.5:0.5b`
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:454: job128_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:460: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:461: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:454: job128_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:460: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:461: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:468: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:469: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:454: job128_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:460: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:461: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:468: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:469: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:454: job128_final=id=128,user_id=16,status=completed,job_type=companion.chat,requested_model=qwen2.5:0.5b,attempts=1,result_rows=1
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:460: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:461: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:468: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:469: (127, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:460: (128, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:13:13Z', '2026-06-24T23:13:15Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:461: (127, 16, 'completed', 'companion.chat', 'qwen2.5:0.5b', 1, '2026-06-24T23:05:29Z', '2026-06-24T23:05:31Z')
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:468: (128, 'completed', 'qwen2.5:0.5b', 1)
docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md:469: (127, 'completed', 'qwen2.5:0.5b', 1)

=== conclusion ===
BO_R3_RECOVERY_RECORDED=PASS
PINPOINT_SUMMARY=live_companion_chat_jobs_insert_requested_model_mock_no_model
REAL_MODEL_AVAILABLE=qwen2.5:0.5b_present_on_CT101_Ollama
WORKER_POSTURE=general_queue_template_present_disabled_ollama_worker_inactive
PATCH_REQUIRED_BEFORE_WORKER=companion_chat_requested_model_must_be_qwen2.5:0.5b_for_new_jobs
EXPECTED_NEXT=FC-O45-E-BP-source_config_patch_companion_chat_requested_model_to_qwen25_no_runtime
EXPECTED_AFTER_BP=FC-O45-E-BQ-bounded_one_job_model_worker_activation_proof
```
