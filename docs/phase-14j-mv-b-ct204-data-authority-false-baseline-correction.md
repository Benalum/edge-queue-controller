# Phase 14J-MV-B — CT204 data_authority=false Baseline Correction

Updated: 2026-06-18

## Status

DOCUMENTATION / SMOKE CORRECTION ONLY.

This phase does not deploy code, restart services, lock/unmount storage, close crypt, create backups, restore databases, start CTs/VMs, change Cloudflare/DNS/tunnels, wake PVESO, or activate workers/models.

## Why this correction exists

Phase 14J-MU-R2 reported:

- `ct204_data_authority=missing`
- `data_authority_paths=absent`

Phase 14J-MV carried that forward as a public status contract warning.

Phase 14J-MV-A then inspected the live public JSON and source context read-only. The compact public JSON showed:

- `private_storage_status.ct204.role=backup-data-only`
- `private_storage_status.ct204.expected_state=stopped`
- `private_storage_status.ct204.data_authority=false`

Therefore, there is no current public CT204 authority contract drift.

## Root cause

The earlier jq extraction used a boolean coalescing pattern with `//`.

In jq, `false // "missing"` returns `"missing"`, so a valid boolean false can be misreported as absent.

Future checks must avoid using `//` for boolean false fields unless they use `has(...)`, `getpath(...)`, or explicit type/path checks.

## Corrected baseline

Corrected carried-forward public status baseline:

- public `/system/status` HTTP 200;
- `overall_state=online`;
- `normalized.schema_version=2`;
- node IDs sorted `ct-203,ct-204,pvew,vm-200`;
- `private_storage_status.policy=manual-unlock-only`;
- `private_storage_status.mount_state=unknown`;
- `private_storage_status.mountpoint=/srv/apc-private-data`;
- `private_storage_status.ct204.expected_state=stopped`;
- `private_storage_status.ct204.data_authority=false`.

## Impact on storage lock planning

Phase 14J-MV remains valid as a no-apply lock plan after this correction.

The apply phase still requires explicit approval and immediate preflight checks before any storage mutation.

The apply phase may use the public CT204 data authority field as one signal, but it must still verify direct PVEW CT204 state before mutation.

## Still gated

Private storage has not been locked/unmounted.

No future apply phase may proceed without explicit approval, immediate active-user checks, backup presence checks, CT203/VM200/CT204 state checks, and abort blockers.

Suggested future approval phrase remains:

`APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE`

## Result

RESULT=PASS_PHASE_14J_MV_B_CT204_DATA_AUTHORITY_FALSE_BASELINE_CORRECTION_DOC_READY
