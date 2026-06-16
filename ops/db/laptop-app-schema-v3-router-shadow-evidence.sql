-- Laptop app schema v3 — Phase 14I-AR
--
-- Adds the controller-owned queued-chat router shadow evidence table.
--
-- This is a schema-only artifact.
-- This file is not applied by Phase 14I-AR.
-- This file adds no writer.
-- This file changes no runtime behavior.
-- This file exposes nothing to the browser.
-- This file does not alter router model selection.
-- This file does not mutate job rows.

BEGIN;

CREATE TABLE IF NOT EXISTS queued_chat_router_shadow_evidence (
    evidence_id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    related_job_id TEXT,
    user_id TEXT,
    request_surface TEXT NOT NULL DEFAULT 'api_chat_queued',
    route_name TEXT NOT NULL DEFAULT 'api_chat_queued',

    shadow_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    router_policy_version TEXT NOT NULL DEFAULT 'unknown',
    router_decision_status TEXT NOT NULL DEFAULT 'not_recorded',
    candidate_route_key TEXT,
    candidate_model_tier TEXT,
    candidate_model_family TEXT,
    decision_confidence NUMERIC(5,4),
    escalation_reason_code TEXT,
    fallback_reason_code TEXT,

    live_requested_model TEXT,
    live_path_preserved BOOLEAN NOT NULL DEFAULT TRUE,
    browser_exposed BOOLEAN NOT NULL DEFAULT FALSE,
    evidence_persisted_by_writer BOOLEAN NOT NULL DEFAULT FALSE,
    route_behavior_changed BOOLEAN NOT NULL DEFAULT FALSE,

    safe_allowlist_version TEXT NOT NULL DEFAULT 'phase-14i-ar-v1',
    rejected_unsafe_field_count INTEGER NOT NULL DEFAULT 0,
    redaction_count INTEGER NOT NULL DEFAULT 0,
    blocked_field_family_code TEXT,

    writer_gate_name TEXT NOT NULL DEFAULT 'EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITER_ENABLED',
    writer_gate_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    notes_code TEXT,

    CONSTRAINT qcrse_confidence_check
        CHECK (decision_confidence IS NULL OR (decision_confidence >= 0 AND decision_confidence <= 1)),

    CONSTRAINT qcrse_rejected_count_check
        CHECK (rejected_unsafe_field_count >= 0),

    CONSTRAINT qcrse_redaction_count_check
        CHECK (redaction_count >= 0),

    CONSTRAINT qcrse_decision_status_check
        CHECK (router_decision_status IN ('not_recorded', 'skipped', 'candidate', 'fallback', 'error')),

    CONSTRAINT qcrse_model_tier_check
        CHECK (
            candidate_model_tier IS NULL
            OR candidate_model_tier IN ('none', 'tiny', 'study', 'companion', 'deep', 'unknown')
        )
);

CREATE INDEX IF NOT EXISTS idx_qcrse_created_at
ON queued_chat_router_shadow_evidence(created_at);

CREATE INDEX IF NOT EXISTS idx_qcrse_related_job_id
ON queued_chat_router_shadow_evidence(related_job_id);

CREATE INDEX IF NOT EXISTS idx_qcrse_request_surface
ON queued_chat_router_shadow_evidence(request_surface);

CREATE INDEX IF NOT EXISTS idx_qcrse_policy_status
ON queued_chat_router_shadow_evidence(router_policy_version, router_decision_status);

CREATE INDEX IF NOT EXISTS idx_qcrse_writer_gate_enabled
ON queued_chat_router_shadow_evidence(writer_gate_enabled);

INSERT INTO app_schema_migrations (version, description)
VALUES (
  'stage-14i-router-shadow-evidence',
  'Add queued_chat_router_shadow_evidence schema-only artifact for router shadow evidence'
)
ON CONFLICT (version) DO NOTHING;

COMMIT;
