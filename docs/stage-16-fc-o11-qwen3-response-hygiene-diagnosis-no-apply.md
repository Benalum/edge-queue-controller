# Stage 16 FC-O11 qwen3 response hygiene diagnosis no-apply

Date: 2026-06-23

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O10-R2.
- Base HEAD/origin/main: `8546444`.
- Base tag: `controller-stage-16-fc-o10-r2-job112-result-recovery-verify-no-further-runtime-2026-06-23`.

## Mutation boundary

This stage is read-only against CT203 and CT101.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- mutate CT101 profile,
- mutate worker files,
- process jobs,
- start runtime,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- call Ollama endpoints,
- pull models,
- restart CTs or VMs.

## FC-O10-R2 finding

Job112 proved qwen3:1.7b can now execute through the CT203 queue after FC-O8.

    job112_status_fc_o11=completed
    job112_attempts_fc_o11=1
    job112_result_rows_fc_o11=1
    job112_response_sha_fc_o11=26e4867bd5ccda6d63c7a546ab1aa707586809eea0dde3ab88e70862128c4a9f
    job112_response_char_len_fc_o11=3732
    job112_result_text_column_fc_o11=response_text

However, the response starts with visible thinking text.

    job112_starts_with_thinking_fc_o11=true
    job112_contains_thinking_fc_o11=true
    job112_strict_response_hygiene_pass_fc_o11=false

Response preview:

    Thinking... Okay, let's see. The user wants me to write exactly one sentence using the words worker, request, result, and default-off. The example given is: "The worker handled the request, saved the result, and returned to default-off i idle posture." First, I need to make sure all four words are included. The original senten sentence uses "worker," "request," "result," and "default-off." The example example sentence is already using those words, but the user might want a di different sentence structure or maybe a different order. Wait, the example is already a valid sentence. But the user might want a va variation. Let me check the original sentence again. The example is correct correct, but maybe the user wants a different sentence. However, the user s says "write exactly one sentence using the words," so maybe the example is acceptable. But perhaps they want a different sentence. Alternatively, maybe the example is correct, and the user is testing if I c can recognize that. But the

## qwen3 profile/worker controls

    profile_sha_fc_o11=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf
    worker_sha_fc_o11=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    qwen3_1_7b_profile_id_fc_o11=qwen3_1_7b_candidate
    qwen3_1_7b_policy_fc_o11=exact_marker_only
    qwen3_1_7b_has_explicit_think_controls_fc_o11=false

Interpretation:

- FC-O8 removed the proven-profile refusal policy.
- FC-O10 proved qwen3:1.7b generation through the queue.
- The qwen3 response is not clean enough for JSON/exact-output tasks because visible thinking text is stored in response_text.
- Running job106 now would likely produce JSON contaminated by thinking text.
- This is an output-control/hygiene issue, not a model reachability issue.

## Preserved queue state

    job105_status_fc_o11=running
    job105_attempts_fc_o11=1
    job105_result_rows_fc_o11=0
    jobs106_111_remain_queued_attempts0_rows0=true
    job112_status_fc_o11=completed
    job112_result_rows_fc_o11=1

## CT101 default-off posture

    active_exact_services_fc_o11=0
    active_exact_timers_fc_o11=0
    active_general_services_fc_o11=0
    active_general_timers_fc_o11=0
    failed_general_units_fc_o11=6
    ct101_fc_o11_read_only_acceptance_pass=true

## Recommended next stage

Do not run job106 yet.

The next apply stage should add qwen3 response hygiene controls before JSON/runtime work.

Conservative remediation options:

1. Profile-only if the worker already supports request/profile options:
   - add explicit qwen3 no-think/hide-thinking options to the qwen3:1.7b profile,
   - do not change gemma/llama profiles,
   - no runtime,
   - no job reset,
   - no failed evidence clearing.

2. Worker-code apply if profile options are not currently consumed:
   - add a qwen-family generation adapter option to suppress visible thinking,
   - optionally strip known leading thinking preambles for qwen candidate profiles,
   - no runtime in the same step,
   - verify loader and focused smoke.

After output hygiene is applied, insert a fresh qwen3 summary or JSON proof job and run it separately.
