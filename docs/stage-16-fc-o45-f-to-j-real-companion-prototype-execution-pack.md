# Stage 16 FC-O45-F to J — Real Companion Prototype Execution Pack

## Purpose

This execution pack bridges the stable Study Companion last-message MVP to the first real model-backed prototype without enabling broad background processing.

Target chain:

```text
authenticated user -> Companion -> Decision Maker -> Study tools/context -> queue/controller -> Ollama model -> result displayed in UI
```

## Files added

```text
edge_modules/companion_decision_maker.py
ops/smoke/check-stage-16-fc-o45-fg-companion-decision-maker.sh
ops/scripts/apc-companion-readonly-baseline.sh
ops/scripts/apc-companion-mock-queue-result.py
ops/scripts/apc-companion-submit-and-read.sh
ops/workers/run-one-companion-ollama-job.py
docs/stage-16-fc-o45-f-to-j-real-companion-prototype-execution-pack.md
```

## Stage F — read-only baseline

Run:

```bash
bash ops/scripts/apc-companion-readonly-baseline.sh
```

Expected:

```text
last_message_mvp_source=present
api_chat_queued_route=present
internal_worker_claim_route=present
wrapper_polling=present
study_command_bridge=present
queued_companion should remain known and intentional
no runtime activation occurs
```

## Stage G — Decision Maker preview

Run:

```bash
bash ops/smoke/check-stage-16-fc-o45-fg-companion-decision-maker.sh
```

This proves the Decision Maker can classify Companion/Study requests without queue writes or model calls.

## Stage I — no-model queue/result proof

Optional and DB-mutating only with approval:

```bash
APPROVE_FC_O45_I_MOCK_QUEUE_RESULT=1 \
python3 ops/scripts/apc-companion-mock-queue-result.py \
  --db /var/lib/edge-queue-controller/edge_queue.sqlite3 \
  --user-id 16 \
  --prompt 'Explain the current Study card briefly.'
```

This creates exactly one `companion.chat` job, inserts exactly one no-model result row, and marks the job completed.

## Stage J — one real Ollama job

Optional and model-calling only with approval:

```bash
APPROVE_FC_O45_J_ONE_REAL_COMPANION_OLLAMA_JOB=1 \
LAPTOP_QUEUE_INTERNAL_TOKEN='<do-not-print>' \
python3 ops/workers/run-one-companion-ollama-job.py \
  --base-url http://127.0.0.1:7070 \
  --job-id <exact queued companion.chat job id> \
  --expected-user-id 16 \
  --model qwen2.5:0.5b
```

Refusal conditions:

```text
missing approval
missing internal token
job id mismatch
not companion.chat
not queued/running after claim
requested model mismatch
user mismatch when expected user is provided
Docker containment mismatch
empty or unsafe visible output
```

## Not included yet

```text
persistent workers
scheduler/timer activation
voice listening/speaking
automatic Study writes
model picker UI
large model default routing
```
