# Stage 16-D1 — Model Runtime Blocker Plan, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-D0 / HEAD 69eae92

## Scope

Stage 16-D1 is a no-apply blocker plan.

It records that Stage 16-D real model activation is currently blocked because no model runtime is installed or available on the current PVEW-hosted platform path.

This phase does not install Ollama.

This phase does not call Ollama.

This phase does not call any model endpoint.

This phase does not write the database.

This phase does not activate workers.

This phase does not activate schedulers.

This phase does not start or stop CTs or VMs.

## Stage 16-D0 readiness result

Stage 16-D0 live readiness evidence passed as a read-only evidence pass.

Safety state was good:

- repo was clean at Stage 16-D0;
- VM200 was running;
- CT203 was running;
- CT204 was stopped;
- private storage was not mounted;
- private storage mapper was absent;
- CT203 controller service was active and enabled;
- VM200 nginx was active;
- VM200 cloudflared was active;
- public /app.js matched the Stage 15-F deployed hash;
- public /api/system/status returned HTTP 200;
- unauthenticated queued chat routes returned HTTP 401 as expected;
- CT203 DB counts stayed unchanged.

## Blocker

Stage 16-D one controlled real-model queue test is blocked.

Observed blocker facts:

- PVEW Ollama binary was absent.
- PVEW Ollama unit files were absent.
- PVEW Ollama processes were absent.
- PVEW Ollama listeners were absent.
- PVEW model storage candidates were missing.
- CT203 Ollama binary was absent.
- CT203 Ollama units, processes, and listeners were absent.
- VM200 Ollama binary was absent.

Therefore, Stage 16-D cannot safely run yet because there is no confirmed model runtime and no confirmed selected model.

## Non-blocker note

The Stage 16-D0 CPU summary had a harmless awk formatting error.

This does not change the blocker decision because model runtime readiness was already blocked by absent Ollama/runtime facts.

## Required next phase

The next safe phase should be Stage 16-E no-apply runtime provisioning plan.

Stage 16-E should decide the exact runtime installation path before any mutation.

The likely target is PVEW, because:

- PVEW is the always-on platform host;
- CT203 is the controller/API/queue authority, not the model runtime host;
- VM200 is public/static edge and should not host model runtime;
- CT204 remains stopped and backup-data-only;
- private storage remains locked and is not required for the first small model test.

## Stage 16-E no-apply plan requirements

Before any install approval, Stage 16-E must specify:

- exact target host;
- exact package/source for Ollama install;
- exact service name;
- exact service enable/start behavior;
- exact model storage path;
- whether model storage uses root disk or a dedicated path;
- exact first model name;
- exact pull/install command if needed;
- exact rollback commands;
- exact post-install checks;
- exact proof that CT204 remains stopped;
- exact proof that private storage remains locked;
- exact proof that no queue worker is activated during install.

## Required future approval phrase

Do not install or start model runtime until the user provides a new explicit approval phrase.

Recommended future approval phrase for runtime provisioning:

APPROVE_STAGE_16_E_PVEW_OLLAMA_RUNTIME_INSTALL_NO_WORKER_NO_SCHEDULER_NO_MODEL_JOB

That approval must still prohibit:

- worker activation;
- scheduler activation;
- DB job creation;
- live model job execution;
- /tick/ollama-direct;
- CT204 start;
- private storage unlock or mount;
- PVESO mutation.

## Later activation phrase remains separate

Even after runtime provisioning, the real one-job model test must still require the separate Stage 16-D approval phrase:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

Runtime installation and real queued model execution must not be combined unless a later approval explicitly says so.
