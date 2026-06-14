# Phase 12R-AJ Repair: System Status Model Memory Top-Level Attachment

This repair fixes a live status shape issue discovered while final-gating Phase 12R-AJ.

## Problem

The actual live /system/status route is:

- system_status
- _system_status_cached_payload
- _system_status_uncached

The _system_status_uncached return payload did not attach model_memory_status at top level.

Earlier smokes recursively searched /system/status for model_memory_status. That worked when the CT101 worker-service status path exposed it. When pveso or CT101 is offline/degraded, that nested path can disappear, causing status-dependent smokes to fail even though the disabled warmup control plane still exists.

A first repair attached the full read-only model-memory scan to top-level /system/status. That proved the shape fix but made /system/status too slow when pveso or CT101 is degraded.

## Repair

Attach a lightweight, public-safe, non-executing, no-network disabled warmup snapshot to top-level /system/status.

The top-level model_memory_status now comes from:

- _stage5p12aj_public_model_memory_status_snapshot

That snapshot includes:

- admin_model_warmup_endpoint
- disabled_future_warmup_execution_skeletons
- runtime_action_available: false
- would_call: none
- network_calls: false

## Safety

This repair must not:

- Enable warmup execution.
- Call Ollama for generation or chat.
- Warm any model.
- Unload any model.
- Start persistent lane workers.
- Enable router rollout.
- Change CT101 worker runtime.
- Print bearer token values.
