from __future__ import annotations

import hashlib
import json
from datetime import datetime


def credit_json_dumps(value):
    try:
        return json.dumps(value, sort_keys=True)
    except Exception:
        return json.dumps({"value": str(value)})


def parse_payload_amount(payload, field="amount", min_amount=1):
    try:
        amount = int(payload.get(field))
    except Exception:
        amount = 0

    if amount < min_amount:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=400,
            detail=f"{field} must be at least {min_amount}.",
        )

    return amount


def credit_pool_debit_plan(
    free_available: int,
    paid_available: int,
    amount: int,
    service_class: str,
    allow_paid_for_local: bool = True,
):
    service_class = str(service_class or "local").strip().lower()

    if amount <= 0:
        return 0, 0

    if service_class == "external_paid":
        if paid_available < amount:
            return None
        return 0, amount

    if service_class != "local":
        from fastapi import HTTPException

        raise HTTPException(
            status_code=400,
            detail="service_class must be local or external_paid.",
        )

    free_to_use = min(free_available, amount)
    remaining = amount - free_to_use

    if remaining <= 0:
        return free_to_use, 0

    if allow_paid_for_local:
        paid_to_use = min(paid_available, remaining)
        remaining -= paid_to_use

        if remaining <= 0:
            return free_to_use, paid_to_use

    return None


def ad_hash(value: str) -> str:
    return hashlib.sha256(str(value or "").encode("utf-8")).hexdigest()


def ad_iso_to_epoch(value: str) -> float:
    if not value:
        return 0.0
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0.0
