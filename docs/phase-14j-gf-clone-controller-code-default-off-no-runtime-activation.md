# Phase 14J-GF - Clone/copy controller code default-off, no runtime activation

PHASE_14J_GF_CLONE_CONTROLLER_CODE_DEFAULT_OFF_NO_RUNTIME_ACTIVATION

PHASE_14J_GF_RESULT=controller_code_copied_to_ct202_default_off_no_runtime_activation

This phase copied the tracked controller repository state into CT 202 edge-controller as a default-off release.

The copy used a tracked Git archive from the laptop repository at commit da0dc2c. It did not copy untracked files, local SQLite database files, venv directories, or local secrets.

## Previous checkpoint

- Previous phase: Phase 14J-GE
- Previous commit: da0dc2c
- Previous tag: controller-phase-14j-ge-edge-controller-baseline-setup-record-2026-06-17

## CT 202 release

PHASE_14J_GF_CT_ID=202

PHASE_14J_GF_HOSTNAME=edge-controller

PHASE_14J_GF_RELEASE=controller-da0dc2c

Installed release layout:

- /srv/edge-controller/app/releases/controller-da0dc2c
- /srv/edge-controller/app/current

Verification:

- edge_controller.py exists in the release
- Python compile check passed
- edge-queue-controller service was not created
- edge-queue-controller runtime was not active
- Docker absent
- Node absent
- npm absent
- nginx absent
- cloudflared absent
- Ollama absent

## Runtime boundary

CT 202 is still not authoritative.

The laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority.

The laptop controller service remains the live controller.

## Not performed

- no controller runtime activation
- no systemd service creation
- no systemd enable
- no systemd start
- no laptop controller stop
- no data migration
- no live DB mutation
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Docker install
- no Node/npm install
- no nginx install
- no cloudflared install
- no Cloudflare route mutation
- no public route mutation
- no raw IP recording
- no auth URL recording
- no Phase 14J-AG apply wrapper rerun

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_gg_ct202_python_venv_dependency_install_default_off_no_runtime_activation
