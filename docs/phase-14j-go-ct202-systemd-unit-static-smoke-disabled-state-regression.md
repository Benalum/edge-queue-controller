# Phase 14J-GO - CT202 systemd unit static smoke and disabled-state regression

PHASE_14J_GO_CT202_SYSTEMD_UNIT_STATIC_SMOKE_DISABLED_STATE_REGRESSION

PHASE_14J_GO_RESULT=ct202_systemd_unit_static_smoke_disabled_state_regression_passed

The user explicitly approved the CT202 systemd unit static smoke and disabled-state regression with:

APPROVE_PHASE_14J_GO_CT202_SYSTEMD_UNIT_STATIC_SMOKE_DISABLED_STATE_REGRESSION

## Verified state

PHASE_14J_GO_CT_ID=202

PHASE_14J_GO_HOSTNAME=edge-controller

PHASE_14J_GO_STATUS=running

PHASE_14J_GO_UNIT_PATH=/etc/systemd/system/edge-queue-controller.service

PHASE_14J_GO_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3

## Verified static unit state

Verified:

- CT202 unit file was present
- CT202 app, venv, and DB were present
- SQLite quick_check passed
- unit LoadState was loaded
- unit file state was disabled
- unit active state was inactive
- unit FragmentPath was /etc/systemd/system/edge-queue-controller.service
- unit WorkingDirectory was /srv/edge-controller/app/current
- unit PYTHONPATH was /srv/edge-controller/app/current
- unit DB environment paths pointed to /srv/edge-controller/data/edge_queue.sqlite3
- unit bind host was 127.0.0.1
- unit bind port was 7070
- unit ExecStart used /srv/edge-controller/venv/bin/python -m uvicorn edge_controller:app
- unit hardening markers were present
- unit contained no public API key
- unit contained no secret token
- unit contained no password
- unit contained no auth URL
- edge controller Uvicorn process was absent
- controller runtime port listeners were absent on 7070, 17070, 17071, and 17072
- systemctl start was not performed
- systemctl enable was not performed
- controller runtime activation was not performed

## Runtime boundary

CT 202 is still not authoritative.

The CT202 service unit exists, but it remains disabled and inactive.

The laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority.

The laptop controller service remains the live controller.

## Not performed

- no daemon-reload in GO
- no systemctl start
- no systemctl enable
- no persistent controller runtime activation
- no persistent Uvicorn process left running
- no public route mutation
- no Cloudflare route mutation
- no laptop controller stop
- no data migration
- no data import
- no live laptop DB mutation
- no controller/queue migration
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no raw IP recording
- no auth URL recording
- no token or password recording
- no public API key recording
- no Phase 14J-AG apply wrapper rerun

## Next safe phase

NEXT_SAFE_PHASE=phase_14j_gp_ct202_systemd_manual_start_loopback_smoke_then_stop_no_enable_requires_explicit_approval
