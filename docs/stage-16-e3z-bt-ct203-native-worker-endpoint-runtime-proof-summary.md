# Stage 16 E3Z-BT — CT203 Native Worker Endpoint Runtime Proof Summary

## Summary

Stages E3Z-BQ through E3Z-BS proved the CT203-native SQLite internal worker endpoint path without the retired Postgres-backed laptop queue routes.

The new endpoint path is:

- CT203 internal worker API namespace: /internal/edge-worker/*
- DB authority: /var/lib/edge-queue-controller/edge_queue.sqlite3
- Token header: X-Laptop-Queue-Token
- Feature flag: EDGE_CT203_SQLITE_WORKER_API_ENABLED=1

## BQ result

BQ enabled the CT203-native SQLite worker API flag and restarted only edge-queue-controller.service.

Validation:

- unauth summary returned HTTP 401
- token-auth summary returned HTTP 200
- summary stage was stage-16-e3z-bo
- DB integrity remained ok
- jobs_total remained 35
- job_results_total remained 14
- jobs 35 and 36 remained queued with attempts 0 and result_rows 0

## BR result

BR proved direct CT203 endpoint claim and completion for job 35 only.

Validation:

- claim endpoint returned HTTP 200
- job 35 moved queued to running
- job 35 attempts advanced from 0 to 1
- complete endpoint returned HTTP 200
- job 35 moved running to completed
- job 35 result_rows advanced from 0 to 1
- job 35 response_text was E3Z-N-A-OK
- job 36 remained queued attempts 0 result_rows 0
- no CT101 worker service was started
- no Docker or Ollama service was started
- no model call was made
- no scheduler or timer activation occurred

## BS result

BS proved CT101-origin bounded one-shot endpoint client claim and completion for job 36 only.

Validation:

- CT101 llms was running
- ai-platform-laptop-queue-worker.service stayed inactive and masked
- docker.service stayed inactive
- ollama.service stayed inactive
- CT101 one-shot client called CT203 at http://192.168.0.250:7070
- claim endpoint returned HTTP 200
- job 36 moved queued to running
- job 36 attempts advanced from 0 to 1
- complete endpoint returned HTTP 200
- job 36 moved running to completed
- job 36 result_rows advanced from 0 to 1
- job 36 response_text was E3Z-N-B-OK

## Final validated state after BS R2

- DB integrity: ok
- jobs_total: 35
- job_results_total: 16
- jobs_status_running: 0
- job 35: completed, attempts 1, requested_model qwen2.5:0.5b, result_rows 1, response_text E3Z-N-A-OK
- job 36: completed, attempts 1, requested_model qwen2.5:0.5b, result_rows 1, response_text E3Z-N-B-OK
- CT101 worker service: inactive and masked
- Docker service: inactive
- Ollama service: inactive

## Safety posture

The CT203-native worker API remains enabled with token authentication.

No persistent worker service is active.

No Docker or Ollama runtime is active.

No scheduler or timer runtime is active.

## Next decision

Before model/Ollama work, decide whether to keep EDGE_CT203_SQLITE_WORKER_API_ENABLED enabled for continued worker integration or roll it back disabled for idle safety.

The next model-facing path should use fresh proof jobs and a separate approval boundary.
