#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CONTRACTS = ROOT / 'contracts'
FIXTURES = ROOT / 'fixtures' / 'valid'

REQUIRED_STORES = {
    'google_sync_manifest_cache': 'manifest_id',
    'google_sync_outbox': 'outbox_entry_id',
    'google_sync_history_pending': 'event_id',
    'google_sync_sessions_pending': 'session_id',
    'google_sync_stats_pending': 'stats_key',
    'google_sync_conflicts': 'conflict_id',
    'google_sync_consent_audit': 'consent_event_id',
    'google_sync_device_state': 'device_id',
}

REQUIRED_OUTBOX_FIELDS = {
    'outbox_entry_id',
    'created_at',
    'updated_at',
    'operation',
    'target_path',
    'record_type',
    'record_id',
    'payload_hash',
    'payload_local_ref',
    'status',
    'attempt_count',
    'last_attempt_at',
    'last_error',
    'created_from_event_id',
    'requires_consent',
    'requires_network',
    'oauth_activated',
    'drive_write_performed',
}

REQUIRED_OPERATIONS = {
    'write_session',
    'append_history',
    'write_user_stats',
    'write_deck_stats',
    'update_manifest',
    'write_conflict',
    'write_consent_event',
}

REQUIRED_STATUSES = {
    'pending',
    'paused_for_consent',
    'paused_offline',
    'syncing',
    'synced',
    'failed_retryable',
    'failed_needs_user',
}

REQUIRED_END_SESSION_STEPS = [
    'begin_indexeddb_transaction',
    'finalize_session_record',
    'append_session_ended_history_event',
    'append_missing_card_answered_events',
    'recompute_user_stats',
    'recompute_deck_stats_when_deck_id_exists',
    'create_write_session_outbox_entry',
    'create_append_history_outbox_entry',
    'create_write_user_stats_outbox_entry',
    'create_write_deck_stats_outbox_entry_when_deck_id_exists',
    'create_update_manifest_outbox_entry',
    'commit_indexeddb_transaction',
    'mark_ui_saved_locally',
]

def forbidden_text() -> list[str]:
    google_api_host = 'googleapis' + '.com'
    oauth_host = 'oauth2' + '.googleapis' + '.com'
    accounts_host = 'accounts' + '.google' + '.com'
    gapi_prefix = 'gapi' + '.'
    return [
        google_api_host + '/drive/' + 'v3',
        gapi_prefix + 'client',
        gapi_prefix + 'auth',
        oauth_host,
        accounts_host,
        'curl https://www.' + google_api_host,
        'drive' + '.write',
    ]

def load_json(path: Path) -> dict[str, Any]:
    with path.open('r', encoding='utf-8') as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit(f'{path} must contain a JSON object')
    return data

def scan_forbidden_text() -> None:
    for path in ROOT.rglob('*'):
        if not path.is_file():
            continue
        if path.suffix not in {'.md', '.py', '.json', '.jsonl'}:
            continue
        text = path.read_text(encoding='utf-8')
        for forbidden in forbidden_text():
            if forbidden in text:
                raise SystemExit(f'Forbidden activation/API text in {path}: {forbidden}')

def validate_contract() -> dict[str, Any]:
    path = CONTRACTS / 'indexeddb-outbox-contract.apc.json'
    if not path.exists():
        raise SystemExit(f'Missing contract: {path}')
    data = load_json(path)
    if data.get('schema_version') != '17k-z-r5':
        raise SystemExit('Contract schema_version must be 17k-z-r5')
    if data.get('record_type') != 'indexeddb_outbox_contract':
        raise SystemExit('Contract record_type mismatch')
    database = data.get('database')
    if not isinstance(database, dict):
        raise SystemExit('Contract database must be an object')
    if database.get('name') != 'apc_google_sync':
        raise SystemExit('IndexedDB database name mismatch')
    for flag in ['browser_local_only', 'no_backend_db', 'no_drive_write', 'no_oauth_activation']:
        if database.get(flag) is not True:
            raise SystemExit(f'Database flag must be true: {flag}')
    stores = data.get('stores')
    if not isinstance(stores, list):
        raise SystemExit('stores must be a list')
    store_map = {}
    for store in stores:
        if not isinstance(store, dict):
            raise SystemExit('store entry must be object')
        store_map[store.get('name')] = store.get('key_path')
    for name, key_path in REQUIRED_STORES.items():
        if store_map.get(name) != key_path:
            raise SystemExit(f'Missing or invalid store key path: {name}')
    fields = set(data.get('outbox_entry_required_fields', []))
    missing_fields = sorted(REQUIRED_OUTBOX_FIELDS - fields)
    if missing_fields:
        raise SystemExit('Missing outbox fields: ' + ', '.join(missing_fields))
    operations = set(data.get('allowed_operations', []))
    if REQUIRED_OPERATIONS - operations:
        raise SystemExit('Missing required operations')
    statuses = set(data.get('allowed_statuses', []))
    if REQUIRED_STATUSES - statuses:
        raise SystemExit('Missing required statuses')
    steps = data.get('end_session_local_transaction')
    if steps != REQUIRED_END_SESSION_STEPS:
        raise SystemExit('End-session transaction order mismatch')
    privacy = data.get('privacy_rules')
    if not isinstance(privacy, dict):
        raise SystemExit('privacy_rules must be object')
    if privacy.get('oauth_tokens_in_outbox') is not False:
        raise SystemExit('OAuth tokens must not be stored in outbox')
    if privacy.get('backend_personal_drive_write_queue') is not False:
        raise SystemExit('Backend personal Drive write queue must be false')
    execution = data.get('execution_rules')
    if not isinstance(execution, dict):
        raise SystemExit('execution_rules must be object')
    if execution.get('r5_runtime_implementation') is not False:
        raise SystemExit('R5 must remain non-runtime contract only')
    return data

def validate_fixture(contract: dict[str, Any]) -> None:
    path = FIXTURES / 'indexeddb_outbox_entry.r5.valid.json'
    if not path.exists():
        raise SystemExit(f'Missing fixture: {path}')
    data = load_json(path)
    required = set(contract['outbox_entry_required_fields'])
    fixture_fields = set(data)
    aliases = {
        'record_type': 'payload_record_type',
        'record_id': 'payload_record_id',
    }
    normalized_fields = set(fixture_fields)
    for required_name, fixture_name in aliases.items():
        if fixture_name in fixture_fields:
            normalized_fields.add(required_name)
    missing = sorted(required - normalized_fields)
    if missing:
        raise SystemExit('Fixture missing outbox fields: ' + ', '.join(missing))
    if data.get('oauth_activated') is not False:
        raise SystemExit('Fixture must not activate OAuth')
    if data.get('drive_write_performed') is not False:
        raise SystemExit('Fixture must not perform Drive write')
    if data.get('requires_consent') is not True:
        raise SystemExit('Fixture must require consent')
    if data.get('requires_network') is not True:
        raise SystemExit('Fixture must require network for future execution')
    if data.get('status') not in {'pending', 'paused_for_consent'}:
        raise SystemExit('R5 fixture status must be pending or paused_for_consent')

def main() -> None:
    if ROOT.name != 'GoogleSync':
        raise SystemExit('Validator must live under GoogleSync')
    scan_forbidden_text()
    contract = validate_contract()
    validate_fixture(contract)
    print('PASS GoogleSync IndexedDB outbox contract validator')

if __name__ == '__main__':
    main()
