# Stage 16 E3P-B — Controlled Dispatch Implementation No-Run

## Purpose

Stage 16 E3P-B patches the controlled operator dispatch artifact so it contains an execution-capable branch for a later explicitly approved runtime phase.

E3P-B itself is no-run. It does not invoke the execution branch and does not contact CT203, PVESO, Ollama, the helper, the adapter, or the DB.

## Current checkpoint

E3P-A completed with:

- Commit: `36cc2a2`
- Tag: `controller-stage-16-e3p-a-controlled-dispatch-runtime-plan-no-apply-2026-06-21`
- Working tree: clean at handoff

## Artifact patched

- `ops/model/operator-dispatch-one-queued-job-via-pveso.sh`

The artifact now supports:

- `--help`
- `--contract`
- `--plan-only`
- `--dry-run`
- `--execute-approved`

## No-run statement

E3P-B does not execute `--execute-approved`.

The smoke only verifies syntax, static safety strings, `--help`, `--contract`, `--plan-only`, and refusal without an approval marker.

## Approval boundary for later execution

The later E3P-D execution branch requires:

`APC_OPERATOR_DISPATCH_APPROVAL=APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION`

Without this exact marker, `--execute-approved` exits before preflight and before any CT203/PVESO/Ollama/helper/adapter/DB contact.

## Implemented future execution behavior

The execution branch is designed to:

1. Require exactly one job ID.
2. Require the exact approval marker.
3. Create and print a durable `run_dir` before long execution.
4. Write `command.env.allowlist.txt`.
5. Write `recovery_hint.txt`.
6. Run CT203 read-only DB preflight.
7. Refuse if target job is not queued.
8. Refuse if target job has any existing `job_results` row.
9. Refuse if requested model is not allowlisted.
10. Check scheduler/persistent worker default-off posture.
11. Run PVESO read-only Ollama localhost/runner/CT101 preflight.
12. Invoke the manual helper for exactly one job ID in the approved execution phase.
13. Capture dispatch stdout and stderr to durable artifacts.
14. Run CT203 read-only DB postflight.
15. Verify exactly one result row after completion.
16. Verify expected response text `APC_E3P_OK`.
17. Verify marker `APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT`.
18. Verify PVESO runner count returns to zero.
19. Write `final_status.txt`.

## E3P-B denied actions

E3P-B denies:

- No DB write.
- No synthetic job insertion.
- No production job mutation.
- No helper execution.
- No adapter execution.
- No operator dispatch execution.
- No CT203 contact.
- No PVESO contact.
- No Ollama contact.
- No service lifecycle mutation.
- No CT/VM lifecycle mutation.
- No scheduler activation.
- No persistent worker activation.
- No model endpoint call.
- No CT101 start.
- No Cloudflare, DNS, tunnel, nginx, or public route mutation.
- No private storage mutation.

## Next phase

Recommended next phase:

- E3P-C: insert one fresh synthetic queued job only.

E3P-C is a real DB write and requires explicit approval:

`APPROVE_STAGE_16_E3P_C_INSERT_ONE_SYNTHETIC_OPERATOR_DISPATCH_JOB_ONLY`

E3P-C must not call PVESO, Ollama, the helper, the adapter, or the operator dispatch execution branch.

## Definition of done

E3P-B is complete when:

- The operator dispatch artifact contains the guarded execution-capable branch.
- The artifact refuses execution without the exact approval marker.
- Static smoke passes without contacting CT203/PVESO/Ollama.
- The repo is committed, tagged, pushed, and clean.
