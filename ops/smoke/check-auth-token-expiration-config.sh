#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import os
from datetime import datetime

from edge_modules.email_verification import (
    email_verification_expires_at,
    password_reset_expires_at,
)

KEYS = [
    "EMAIL_VERIFICATION_TOKEN_MINUTES",
    "EMAIL_VERIFICATION_TOKEN_HOURS",
    "PASSWORD_RESET_TOKEN_MINUTES",
    "PASSWORD_RESET_TOKEN_HOURS",
]

original = {k: os.environ.get(k) for k in KEYS}

try:
    now = "2026-06-05T12:00:00+00:00"
    start = datetime.fromisoformat(now)

    os.environ["EMAIL_VERIFICATION_TOKEN_MINUTES"] = "15"
    os.environ["PASSWORD_RESET_TOKEN_MINUTES"] = "15"

    email_exp = datetime.fromisoformat(email_verification_expires_at(now))
    reset_exp = datetime.fromisoformat(password_reset_expires_at(now))

    assert int((email_exp - start).total_seconds()) == 900
    assert int((reset_exp - start).total_seconds()) == 900

    # Backward compatibility: hours still work if minutes are not set.
    os.environ.pop("EMAIL_VERIFICATION_TOKEN_MINUTES", None)
    os.environ.pop("PASSWORD_RESET_TOKEN_MINUTES", None)
    os.environ["EMAIL_VERIFICATION_TOKEN_HOURS"] = "2"
    os.environ["PASSWORD_RESET_TOKEN_HOURS"] = "3"

    email_exp = datetime.fromisoformat(email_verification_expires_at(now))
    reset_exp = datetime.fromisoformat(password_reset_expires_at(now))

    assert int((email_exp - start).total_seconds()) == 7200
    assert int((reset_exp - start).total_seconds()) == 10800

finally:
    for key, value in original.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value

print("PASS: auth email token expiration config supports 15-minute links")
PY
