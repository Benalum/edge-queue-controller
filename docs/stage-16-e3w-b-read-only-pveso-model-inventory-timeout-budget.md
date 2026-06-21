# Stage 16 E3W-B — Read-Only PVESO Model Inventory and Timeout Budget

## Result

E3W-B completed a read-only PVESO model inventory and timeout budget check.

Final marker:

    E3W_B_PVESO_READ_ONLY_INVENTORY_OK

Corrected model recommendation for the next timeout-safe proof:

    E3W_B_CORRECTED_RECOMMENDED_MODEL=none_small_fast_local_model_present

Reason:

    PVESO currently has only two known-present local models in this inventory.
    Both are 19 GB / 32B-class models.
    The initial heuristic selected qwen2.5-coder:32b-instruct-q4_K_M because the pattern overmatched 32b as a small-model token.
    That is not a safe small/fast model choice for the next timeout-proof runtime test.

Inventory models observed:

    qwen2.5-coder:32b-instruct-q4_K_M
    qwen2.5:32b-instruct-q4_K_M

Corrected timeout budget if no smaller model is installed:

    model_timeout_seconds=45
    wrapper_total_seconds=120
    ppb_outer_seconds_at_least=300
    num_predict=8
    temperature=0
    stream=false

Corrected next-step recommendation:

    Do not run another 32B runtime proof until the wrapper has internal timeout/failure handling.
    Prefer installing or selecting a smaller known-present local model in a separately approved model-prep phase.
    If using an existing 32B model anyway, use num_predict=8 and model_timeout_seconds=45, and require the wrapper to mark the job failed internally on timeout.

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 62c0da8
    Previous tag: controller-stage-16-e3w-a-runtime-timeout-prevention-design-no-apply-2026-06-21
    Working tree: clean

## Safety boundary

E3W-B did not:

- write the DB
- apply a schema migration
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- run execute-approved
- call the helper
- call the adapter
- call a model
- call prompt/completion/generate/chat/embed
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## PVESO inventory output

```text
PVESO_TAILSCALE_STATUS_LOOKUP=OK
OLLAMA_SERVICE_STATE=active
OLLAMA_LISTENERS_BEGIN
LISTEN 0      4096                     127.0.0.1:11434 0.0.0.0:* users:(("ollama",pid=339134,fd=3))                                                                                                       
OLLAMA_LISTENERS_END
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0
CT101_STATUS=stopped
CT101_ONBOOT=0
OLLAMA_MODEL_LIST_BEGIN
NAME                                 ID              SIZE     MODIFIED     
qwen2.5-coder:32b-instruct-q4_K_M    b92d6a0bd47e    19 GB    4 months ago    
qwen2.5:32b-instruct-q4_K_M          9f13ba1299af    19 GB    4 months ago    
OLLAMA_MODEL_LIST_END
E3W_B_PVESO_READ_ONLY_INVENTORY_OK
```

## Model choice output

```text
E3W_B_LOCAL_MODEL_COUNT=2
E3W_B_LOCAL_MODEL name=qwen2.5-coder:32b-instruct-q4_K_M size=19 GB
E3W_B_LOCAL_MODEL name=qwen2.5:32b-instruct-q4_K_M size=19 GB
E3W_B_RECOMMENDED_MODEL=qwen2.5-coder:32b-instruct-q4_K_M
E3W_B_RECOMMENDED_MODEL_REASON=matched_preferred_pattern=(?i)(qwen|gemma|phi|llama).*(2b|3b|4b)
E3W_B_RECOMMENDED_NUM_PREDICT=16
E3W_B_RECOMMENDED_MODEL_TIMEOUT_SECONDS=60
E3W_B_RECOMMENDED_WRAPPER_TOTAL_SECONDS=180
E3W_B_RECOMMENDED_PPB_OUTER_SECONDS_AT_LEAST=300
E3W_B_MODEL_SELECTION_STATUS=selected_known_present_local_model
```

## Interpretation

E3W-B chose a known-present local model without making a model generation call.

The next stage should be:

    E3W-C — implement timeout-safe wrapper changes, no run

E3W-C should implement:

    model_timeout_seconds=60
    wrapper_total_seconds=180
    num_predict=16
    internal failure update after claim if model timeout/error occurs
    no job 29 reuse
    no E3V-Q rerun

## Hard rule

Do not rerun E3V-Q.

Do not retry job 29.

The next runtime proof must use a new job id.

## E3W-B-R1 corrected interpretation

E3W-B-R1 corrected the model-selection interpretation.

The read-only inventory itself remains valid:

    E3W_B_LOCAL_MODEL_COUNT=2
    qwen2.5-coder:32b-instruct-q4_K_M size=19 GB
    qwen2.5:32b-instruct-q4_K_M size=19 GB

Corrected conclusion:

    E3W_B_CORRECTED_RECOMMENDED_MODEL=none_small_fast_local_model_present
    E3W_B_SELECTION_HEURISTIC_OVERMATCHED_32B=true
    E3W_B_DO_NOT_TREAT_32B_AS_SMALL_FAST_MODEL=true

The next runtime proof must still use a new job id and must not retry job 29.
