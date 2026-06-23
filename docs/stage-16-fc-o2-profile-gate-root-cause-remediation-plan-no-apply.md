# Stage 16 FC-O2 profile gate root-cause remediation plan no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O1.
- Base HEAD/origin/main: `675a797`.
- Base tag: `controller-stage-16-fc-o1-failed-unit-journal-diagnosis-read-only-2026-06-22`.

## Mutation boundary

This stage is repo documentation only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- mutate CT101 profile files,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd unit files,
- run daemon-reload,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama endpoints,
- pull or download models,
- restart CTs or VMs.

## FC-O1 finding

FC-O1 proved the FC-N non-qwen2.5 failures were not generation failures.

The failed units exited immediately by worker guard refusal:

| Job | Model | Lane | Journal refusal | Meaning |
|---|---|---|---|---|
| 97 | qwen3:1.7b | summary | `REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE` | profile exists, but lane is not allowed |
| 99 | qwen3:1.7b | json_response | `REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE` | profile exists, but lane is not allowed |
| 100 | gemma4:e4b | companion_chat | `REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE` | profile exists, but lane is not allowed |
| 101 | gemma3:4b | companion_chat | `REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE` | profile exists, but lane is not allowed |
| 104 | llama3.2:3b | safe_refusal | `REFUSE_NO_PROFILE_FOR_MODEL` | no matching profile exists |

FC-O1 did not find evidence of:

- model generation timeout,
- Ollama connection failure,
- model-not-found HTTP failure,
- SQLite/database error,
- JSON decoding error,
- Python traceback.

## Corrected interpretation

The prior FC-N matrix should be interpreted as follows:

- qwen2.5 FC semantic probes reached model execution and produced result rows.
- qwen3, gemma4, gemma3, and llama3.2 probes did not reach model execution.
- Their stale CT203 states are an artifact of guarded worker refusal after claim.
- The active issue is profile-gate/productization configuration, not model capacity or runtime quality.

## Remediation design

A future apply stage should be explicit and narrow. It should mutate only the CT101 model profile file and should not run jobs.

Recommended profile changes:

1. Add a safe FC-only qwen3:1.7b remediation profile, or extend the existing qwen3:1.7b candidate profile, to allow:
   - `stage16_fc_summary_semantic_probe`
   - `stage16_fc_json_semantic_probe`

2. Add a safe FC-only gemma4:e4b remediation profile, or extend the existing gemma4:e4b candidate profile, to allow:
   - `stage16_fc_companion_chat_semantic_probe`
   - `stage16_fc_study_tutor_semantic_probe`
   - `stage16_fc_flashcards_semantic_probe`

3. Add a safe FC-only gemma3:4b remediation profile, or extend the existing gemma3:4b candidate profile, to allow:
   - `stage16_fc_companion_chat_semantic_probe`

4. Add a safe FC-only llama3.2:3b profile to allow:
   - `stage16_fc_safe_refusal_semantic_probe`

## Guardrails for the profile apply

The profile apply stage must:

- be approved explicitly,
- backup the CT101 profile file first,
- mutate only `/etc/edge-ct101-worker/model-profiles.yaml`,
- preserve worker file sha,
- run no jobs,
- start no timers or services,
- call no model endpoints,
- pull no models,
- reset no failed units,
- clear no failed evidence,
- write no CT203 DB state,
- verify exact allowed job type changes,
- verify profile yaml parses,
- verify all model candidate profiles remain disabled by default,
- commit/tag/push the profile-change checkpoint.

## Guardrails for later job cleanup/retry

Do not reuse jobs97, 99, 100, 101, or 104 until a separate cleanup/retry decision exists.

Preferred recovery path after profile apply:

- create new replacement jobs instead of resetting old stale jobs, or
- explicitly mark stale jobs as preserved evidence and create fresh job IDs for post-remediation probes.

Reason:

- existing stale jobs are valuable evidence for profile-gate diagnosis,
- resetting them would blur the audit trail,
- replacement jobs provide a clean before/after comparison.

## Decision

Stop FC-N runtime remains in force.

Do not run jobs102 or 103.

Do not retry jobs97, 99, 100, 101, or 104.

Do not reset or clear failed units.

Proceed to an explicitly approved profile-only apply stage when ready.
