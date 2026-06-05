from __future__ import annotations

import hashlib
import json
from datetime import datetime

from fastapi import HTTPException


def credit_json_dumps(value):
    if value is None:
        return None

    try:
        return json.dumps(value, sort_keys=True)
    except Exception:
        return json.dumps({"value": str(value)})


def parse_payload_amount(payload, field="amount", min_amount=1):
    try:
        amount = int(payload.get(field))
    except Exception:
        raise HTTPException(status_code=400, detail=f"{field} must be an integer.")

    if amount < min_amount:
        raise HTTPException(status_code=400, detail=f"{field} must be at least {min_amount}.")

    return amount


def credit_pool_debit_plan(
    free_available: int,
    paid_available: int,
    amount: int,
    service_class: str,
    allow_paid_for_local: bool = True,
):
    service_class = str(service_class or "local").strip().lower()

    if service_class not in ("local", "external_paid"):
        raise HTTPException(status_code=400, detail="service_class must be 'local' or 'external_paid'.")

    amount = int(amount)

    if service_class == "external_paid":
        if paid_available < amount:
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient paid credits. External paid services require paid credits. Required {amount}, paid available {paid_available}.",
            )
        return 0, amount

    # Local jobs can use free credits first.
    free_to_use = min(free_available, amount)
    remaining = amount - free_to_use

    paid_to_use = 0
    if remaining > 0:
        if not allow_paid_for_local:
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient free/local credits. Required {amount}, free available {free_available}.",
            )

        if paid_available < remaining:
            raise HTTPException(
                status_code=402,
                detail=f"Insufficient credits. Required {amount}, free available {free_available}, paid available {paid_available}.",
            )

        paid_to_use = remaining

    return free_to_use, paid_to_use


def ad_hash(value: str) -> str:
    return hashlib.sha256(str(value or "").encode("utf-8")).hexdigest()


def ad_iso_to_epoch(value: str) -> float:
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except Exception:
        return 0.0
