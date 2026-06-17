# Phase 14J-FW - Default-preserving controller DB path env override, no runtime reload

PHASE_14J_FW_DEFAULT_PRESERVING_CONTROLLER_DB_PATH_ENV_OVERRIDE_NO_RUNTIME_RELOAD

PHASE_14J_FW_RESULT=default_preserving_controller_db_path_env_override_added_no_runtime_reload

This phase adds code support for a configurable SQLite DB path while preserving current default behavior.

Default DB path remains: edge_queue.sqlite3

Environment override order:

1. EDGE_QUEUE_SQLITE_DB_PATH
2. EDGE_QUEUE_DB_PATH
3. EDGE_CONTROLLER_DB_PATH
4. fallback edge_queue.sqlite3

Runtime boundary:

- no container creation
- no data migration
- no live DB mutation
- no controller/queue migration
- no service restart/reload
- no runtime config change
- no systemd mutation
- no env file mutation
- no worker start
- no production DB/job mutation
- no CT101 call
- no model/Ollama endpoint call
- no Cloudflare route mutation
- no Phase 14J-AG apply wrapper rerun

Code behavior:

edge_controller.py now resolves DB_PATH from EDGE_QUEUE_SQLITE_DB_PATH, EDGE_QUEUE_DB_PATH, EDGE_CONTROLLER_DB_PATH, then falls back to edge_queue.sqlite3.

The currently running controller remains unchanged until a later explicit runtime apply.

NEXT_SAFE_PHASE=phase_14j_fx_data_container_or_vm_target_design_no_creation
