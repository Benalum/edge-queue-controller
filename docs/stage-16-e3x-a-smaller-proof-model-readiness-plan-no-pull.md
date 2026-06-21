# Stage 16 E3X-A — Smaller Proof Model Readiness Plan, No Pull

## Result

E3X-A completed a read-only readiness plan for a smaller local proof model on PVESO.

Final marker:

    E3X_A_SMALLER_PROOF_MODEL_READINESS_PLAN_NO_PULL_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: e767777
    Previous tag: controller-stage-16-e3w-g-r1-final-timeout-safe-runtime-closure-refined-runner-check-2026-06-21
    Working tree: clean

## Why this phase exists

E3W proved the timeout-safe wrapper failure path.

The 32B model timed out inside the bounded 45-second proof call, but the wrapper correctly marked job 30 failed and avoided the E3V-Q stuck-running failure mode.

The next useful proof is a completion-path proof using a much smaller local model.

## CT203 DB readiness

```text
E3X_A_CT203_DB_READINESS=begin
DB_INTEGRITY=ok
JOBS_TOTAL=29
JOB_RESULTS_TOTAL=10
JOB_29_STATE id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 updated_at=2026-06-21T19:46:39.173248Z
JOB_30_STATE id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 updated_at=2026-06-21T20:04:30.088429Z
E3X_A_RUNNING_E3V_E3W_E3X_JOB_COUNT=0
E3X_A_ELIGIBLE_E3V_E3W_E3X_JOB_COUNT=0
E3X_A_CT203_DB_READINESS_OK
```

## PVESO readiness

```text
E3X_A_PVESO_READINESS=begin
--- host ---
 Static hostname: pveso
       Icon name: computer-desktop
         Chassis: desktop 🖥️
      Machine ID: 2ee5763cb3664d49ab1a2e5c8bfdc84f
         Boot ID: b77bba4352c2495884948525e9d91b3b
    Product UUID: 0818e038-e6a8-0516-a94c-d8bbc103fc33
Operating System: Debian GNU/Linux 13 (trixie)
          Kernel: Linux 6.17.9-1-pve
--- resources ---
CPU_COUNT=20
               total        used        free      shared  buff/cache   available
Mem:            31Gi       2.5Gi        20Gi        46Mi       9.1Gi        28Gi
Swap:           15Gi        16Ki        15Gi
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/pve-root     118G   77G   35G  69% /
/dev/mapper/pve-root     118G   77G   35G  69% /
/dev/mapper/pve-vzstore  295G   48G  248G  17% /var/lib/vz
--- ollama service/listener ---
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
--- active clients / loaded runners ---
PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_COUNT=0
--- local models ---
NAME                                 ID              SIZE     MODIFIED     
qwen2.5-coder:32b-instruct-q4_K_M    b92d6a0bd47e    19 GB    4 months ago    
qwen2.5:32b-instruct-q4_K_M          9f13ba1299af    19 GB    4 months ago    
--- CT101 ---
CT101_STATUS=stopped
CT101_ONBOOT=0
E3X_A_LOCAL_MODEL_COUNT=2
E3X_A_SMALL_LOCAL_MODEL_PRESENT=false
E3X_A_RECOMMENDED_PROOF_MODEL_CANDIDATE=qwen2.5:0.5b
E3X_A_FALLBACK_PROOF_MODEL_CANDIDATE=qwen2.5:1.5b
E3X_A_MODEL_PULL_REQUIRED_IF_SMALL_LOCAL_MODEL_PRESENT_FALSE=true
E3X_A_PVESO_READINESS_OK
```

## Smaller model decision

Observed local model count:

    E3X_A_LOCAL_MODEL_COUNT=2

Small local model currently present:

    E3X_A_SMALL_LOCAL_MODEL_PRESENT=false

Recommended proof candidate:

    E3X_A_RECOMMENDED_PROOF_MODEL_CANDIDATE=qwen2.5:0.5b

Fallback proof candidate:

    E3X_A_FALLBACK_PROOF_MODEL_CANDIDATE=qwen2.5:1.5b

If no small local model is present, E3X-B must be an explicitly approved model pull/download phase.

## E3X-B approval boundary

E3X-B may pull one small model only if explicitly approved.

Candidate approval phrase:

    APPROVE_STAGE_16_E3X_B_PULL_ONE_SMALL_PROOF_MODEL_QWEN25_05B_ONLY

E3X-B must not:

- insert a job
- claim a job
- call generate/chat/embed
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- pull more than one model

## Future proof path

After a small model is present:

1. E3X-C insert one fresh small-model proof job.
2. E3X-D dry-run timeout-safe wrapper would-claim that fresh job.
3. E3X-E approved runtime proof using the small model.

## Safety boundary

E3X-A did not:

- write the DB
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- call a model
- pull a model
- install packages
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Use a fresh job id for any future runtime proof.
