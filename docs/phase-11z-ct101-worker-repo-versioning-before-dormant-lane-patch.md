# Phase 11Z CT101 Worker Repo Versioning Before Dormant Lane Patch

Phase 11Z records the CT101 /opt/ai-platform repo state before patching worker-side queue_lane support.

## Purpose

Phase 11W added optional queue_lane support to the laptop controller claim endpoint.
Phase 11X proved the live controller endpoint accepts queue_lane.
Phase 11Y proved CT101 worker-side code still does not send queue_lane.

Phase 11Z documents CT101 repo/versioning risk before touching CT101 worker files.

## CT101 repo state

CT101 path: /opt/ai-platform.
CT101 is a git repo.
CT101 main branch is at 9b13fe1.
CT101 origin/main is also at 9b13fe1.

Existing unrelated dirty state was observed before any Phase 11Z patch:

- modified docker-compose.yml
- modified ops/ct101-scripts/ai-platform-send-edge-heartbeat
- untracked ops/runtime/

The untracked ops/runtime directory matters because the active worker service uses runtime scripts from that directory.

## Target worker files

Target files inspected before patching:

- backend/app/worker/laptop_queue_client.py
- ops/smoke/laptop_queue_bounded_synthetic_poller.py
- ops/runtime/laptop-queue-worker-loop.sh
- ops/runtime/laptop-queue-worker-preflight.sh

Current worker-side claim behavior:

- claim_one(self, job_type="ollama_chat")
- claim payload includes worker_id
- claim payload includes job_type
- claim payload does not include queue_lane
- bounded poller calls client.claim_one(job_type=job_types[0])

## Safety boundary

Phase 11Z is documentation/source-map only.
Phase 11Z does not patch CT101.
Phase 11Z does not restart CT101 worker.
Phase 11Z does not change LAPTOP_QUEUE_MAX_JOBS_PER_RUN.
Phase 11Z does not change OLLAMA_NUM_PARALLEL.
Phase 11Z does not change schema.

## Recommended next patch strategy

Because CT101 already has unrelated dirty files, the next phase should not rely on a perfectly clean CT101 git tree.

Next phase should:

- create timestamped backups of the target CT101 files
- patch only backend/app/worker/laptop_queue_client.py
- patch only ops/smoke/laptop_queue_bounded_synthetic_poller.py
- leave ops/runtime files unchanged
- leave docker-compose.yml unchanged
- leave ops/ct101-scripts/ai-platform-send-edge-heartbeat unchanged
- do not restart the CT101 worker yet
- keep LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1
- keep OLLAMA_NUM_PARALLEL unchanged

The dormant worker-side patch should add optional queue_lane support but only send it when LAPTOP_QUEUE_QUEUE_LANE is explicitly set.

## Runtime changes

None in Phase 11Z.
