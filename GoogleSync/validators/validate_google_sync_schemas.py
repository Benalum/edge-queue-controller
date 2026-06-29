#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / 'schemas'
FIXTURES = ROOT / 'fixtures' / 'valid'

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

EXPECTED_SCHEMAS = {
    'manifest.schema.json': 'google_sync_manifest',
    'deck.schema.json': 'deck',
    'card.schema.json': 'card',
    'session.schema.json': 'study_session',
    'user_stats.schema.json': 'user_stats',
    'deck_stats.schema.json': 'deck_stats',
    'history_event.schema.json': 'study_history_event',
    'conflict.schema.json': 'sync_conflict',
    'outbox_entry.schema.json': 'google_sync_outbox_entry',
    'consent_event.schema.json': 'google_sync_consent_event',
}

FIXTURE_TO_SCHEMA = {
    'manifest.valid.json': 'manifest.schema.json',
    'deck.valid.json': 'deck.schema.json',
    'card.valid.json': 'card.schema.json',
    'session.valid.json': 'session.schema.json',
    'user_stats.valid.json': 'user_stats.schema.json',
    'deck_stats.valid.json': 'deck_stats.schema.json',
    'history_event.valid.json': 'history_event.schema.json',
    'conflict.valid.json': 'conflict.schema.json',
    'outbox_entry.valid.json': 'outbox_entry.schema.json',
    'consent_event.valid.json': 'consent_event.schema.json',
}

def load_json(path: Path) -> dict[str, Any]:
    with path.open('r', encoding='utf-8') as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise SystemExit(f'{path} must contain a JSON object')
    return data

def check_forbidden_text() -> None:
    for path in ROOT.rglob('*'):
        if not path.is_file():
            continue
        if path.suffix not in {'.md', '.py', '.json', '.jsonl'}:
            continue
        text = path.read_text(encoding='utf-8')
        for forbidden in forbidden_text():
            if forbidden in text:
                raise SystemExit(f'Forbidden activation/API text in {path}: {forbidden}')

def validate_schema_file(name: str, expected_record_type: str) -> dict[str, Any]:
    path = SCHEMAS / name
    if not path.exists():
        raise SystemExit(f'Missing schema: {path}')
    data = load_json(path)
    if data.get('x_apc_stage') != '17K-Z-R4':
        raise SystemExit(f'{path} missing x_apc_stage 17K-Z-R4')
    if data.get('x_no_oauth') is not True:
        raise SystemExit(f'{path} must declare x_no_oauth true')
    if data.get('x_no_drive_writes') is not True:
        raise SystemExit(f'{path} must declare x_no_drive_writes true')
    required = data.get('required')
    properties = data.get('properties')
    if not isinstance(required, list) or not required:
        raise SystemExit(f'{path} required must be a non-empty list')
    if not isinstance(properties, dict) or not properties:
        raise SystemExit(f'{path} properties must be a non-empty object')
    for field in required:
        if field not in properties:
            raise SystemExit(f'{path} required field not in properties: {field}')
    record_type_schema = properties.get('record_type', {})
    if record_type_schema.get('const') != expected_record_type:
        raise SystemExit(f'{path} record_type const mismatch')
    return data

def type_matches(value: Any, expected: Any) -> bool:
    if isinstance(expected, list):
        return any(type_matches(value, item) for item in expected)
    if expected == 'null':
        return value is None
    if expected == 'string':
        return isinstance(value, str)
    if expected == 'integer':
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == 'number':
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    if expected == 'boolean':
        return isinstance(value, bool)
    if expected == 'array':
        return isinstance(value, list)
    if expected == 'object':
        return isinstance(value, dict)
    return True

def validate_fixture(path: Path, schema: dict[str, Any]) -> None:
    data = load_json(path)
    required = schema['required']
    properties = schema['properties']
    for field in required:
        if field not in data:
            raise SystemExit(f'{path} missing required field: {field}')
    for field, rules in properties.items():
        if field not in data:
            continue
        if 'const' in rules and data[field] != rules['const']:
            raise SystemExit(f'{path} field {field} must equal {rules["const"]}')
        if 'enum' in rules and data[field] not in rules['enum']:
            raise SystemExit(f'{path} field {field} has invalid enum value {data[field]}')
        if 'type' in rules and not type_matches(data[field], rules['type']):
            raise SystemExit(f'{path} field {field} has wrong type')

def main() -> None:
    if ROOT.name != 'GoogleSync':
        raise SystemExit('Validator must live under the GoogleSync folder')
    check_forbidden_text()
    loaded_schemas = {}
    for name, record_type in EXPECTED_SCHEMAS.items():
        loaded_schemas[name] = validate_schema_file(name, record_type)
    for fixture_name, schema_name in FIXTURE_TO_SCHEMA.items():
        fixture_path = FIXTURES / fixture_name
        if not fixture_path.exists():
            raise SystemExit(f'Missing fixture: {fixture_path}')
        validate_fixture(fixture_path, loaded_schemas[schema_name])
    print('PASS GoogleSync local schema validators')

if __name__ == '__main__':
    main()
