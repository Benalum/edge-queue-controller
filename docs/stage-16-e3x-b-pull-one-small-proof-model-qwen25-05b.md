# Stage 16 E3X-B — Pull One Small Proof Model qwen2.5:0.5b

## Result

E3X-B consumed the approved model-pull boundary and pulled exactly one small proof model on PVESO.

Final marker:

    E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_OK

## Approval

Explicit approval was provided and consumed:

    APPROVE_STAGE_16_E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_ONLY

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 64a4d5a
    Previous tag: controller-stage-16-e3x-b0-container-docker-model-inventory-no-pull-2026-06-21
    Working tree: clean

## Pulled model

    model=qwen2.5:0.5b
    scope=one_model_only
    host=PVESO
    runtime=host Ollama
    visible_to_host_ollama=true

Local model count after pull:

    E3X_B_LOCAL_MODEL_COUNT_AFTER=3

## Preflight

```text
E3X_B_PREFLIGHT=begin
MODEL_TO_PULL=qwen2.5:0.5b
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_COUNT=0
CT101_STATUS=stopped
CT101_ONBOOT=0
--- models before ---
NAME                                 ID              SIZE     MODIFIED     
qwen2.5-coder:32b-instruct-q4_K_M    b92d6a0bd47e    19 GB    4 months ago    
qwen2.5:32b-instruct-q4_K_M          9f13ba1299af    19 GB    4 months ago    
E3X_B_PREFLIGHT_OK
```

## Pull output

```text
E3X_B_APPROVED_MODEL_PULL=begin
E3X_B_PULL_MODEL=qwen2.5:0.5b
E3X_B_PULL_SCOPE=one_model_only
NO_GENERATE_CALL
NO_CHAT_CALL
NO_EMBED_CALL
E3X_B_APPROVED_MODEL_PULL_DONE
```

## Postflight

```text
E3X_B_POSTFLIGHT=begin
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
CT101_STATUS=stopped
CT101_ONBOOT=0
--- models after ---
NAME                                 ID              SIZE      MODIFIED     
qwen2.5:0.5b                         a8b0c5157701    397 MB    1 second ago    
qwen2.5-coder:32b-instruct-q4_K_M    b92d6a0bd47e    19 GB     4 months ago    
qwen2.5:32b-instruct-q4_K_M          9f13ba1299af    19 GB     4 months ago    
E3X_B_LOCAL_MODEL_COUNT_AFTER=3
E3X_B_SMALL_PROOF_MODEL_PRESENT_AFTER=true
E3X_B_PULLED_MODEL_VISIBLE_TO_HOST_OLLAMA=qwen2.5:0.5b
E3X_B_POSTFLIGHT_OK
```

## Safety boundary

E3X-B did not:

- write the DB
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- call a model generation endpoint
- call prompt/completion/generate/chat/embed
- docker pull
- start Docker
- stop Docker
- install packages
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Next phase

Recommended next phase:

    E3X-C — insert one fresh small-model proof job

E3X-C requires explicit approval because it inserts a DB job.

Expected job target:

    requested_model=qwen2.5:0.5b
    job_type=stage16_e3x_small_model_timeout_safe_completion_smoke

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Use a fresh job id for the small-model completion proof.
