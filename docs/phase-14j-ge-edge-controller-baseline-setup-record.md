# Phase 14J-GE - edge-controller baseline setup record

PHASE_14J_GE_EDGE_CONTROLLER_BASELINE_SETUP_RECORD

PHASE_14J_GE_RESULT=edge_controller_baseline_setup_completed_no_runtime_activation

The user explicitly approved the baseline setup phase with:

APPROVE_PHASE_14J_GE_START_EDGE_CONTROLLER_BASELINE_SETUP_ONLY

## Verified CT 202 state

PHASE_14J_GE_CT_ID=202

PHASE_14J_GE_HOSTNAME=edge-controller

PHASE_14J_GE_STATUS=running

The baseline setup completed on CT 202.

Installed baseline package/tooling set:

- python3
- python3-venv
- python3-pip
- git
- sqlite3
- rsync
- ca-certificates
- openssh-server

Created private directories:

- /srv/edge-controller/app
- /srv/edge-controller/data
- /srv/edge-controller/backups
- /srv/edge-controller/logs

Forbidden runtime stacks verified absent:

- FORBIDDEN_ABSENT=docker
- FORBIDDEN_ABSENT=node
- FORBIDDEN_ABSENT=npm
- FORBIDDEN_ABSENT=nginx
- FORBIDDEN_ABSENT=cloudflared
- FORBIDDEN_ABSENT=ollama

## Runtime boundary

CT 202 is running only as a baseline container.

Not performed:

- no package install rerun in record phase
- no controller code clone
- no controller runtime activation
- no data migration
- no live DB mutation
- no laptop controller stop
- no laptop service restart/reload
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no Phase 14J-AG apply wrapper rerun

## Authority boundary

The laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority.

CT 202 is not yet authoritative and is not yet serving controller API traffic.

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_gf_clone_controller_code_default_off_no_runtime_activation
