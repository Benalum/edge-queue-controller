from __future__ import annotations

import hashlib
import os
import secrets
import smtplib
import ssl
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from urllib.parse import quote


def email_verification_token() -> str:
    return secrets.token_urlsafe(48)


def email_verification_hash(token: str) -> str:
    return hashlib.sha256(str(token).encode("utf-8")).hexdigest()


def email_verification_hours() -> int:
    try:
        hours = int(os.getenv("EMAIL_VERIFICATION_TOKEN_HOURS", "24"))
    except Exception:
        hours = 24

    return max(1, min(hours, 168))


def email_verification_expires_at(now_iso: str) -> str:
    try:
        now = datetime.fromisoformat(str(now_iso).replace("Z", "+00:00"))
    except Exception:
        now = datetime.now(timezone.utc)

    return (now + timedelta(hours=email_verification_hours())).isoformat()


def email_verification_base_url() -> str:
    return str(os.getenv("PUBLIC_BASE_URL", "https://alexhartel.com")).rstrip("/")


def email_verification_url(token: str) -> str:
    return f"{email_verification_base_url()}/verify-email?token={quote(str(token))}"


def email_verification_debug_return_url() -> bool:
    return str(os.getenv("EMAIL_VERIFICATION_DEBUG_RETURN_URL", "false")).strip().lower() in (
        "1",
        "true",
        "yes",
        "on",
    )


def send_email_verification(email: str, verify_url: str):
    smtp_enabled = str(os.getenv("EMAIL_VERIFICATION_SMTP_ENABLED", "false")).strip().lower() in (
        "1",
        "true",
        "yes",
        "on",
    )

    from_email = str(os.getenv("EMAIL_FROM", "no-reply@alexhartel.com")).strip()
    from_name = str(os.getenv("EMAIL_FROM_NAME", "AlexHartel AI Platform")).strip()
    subject = str(os.getenv("EMAIL_VERIFICATION_SUBJECT", "Verify your email address")).strip()

    result = {
        "sent": False,
        "delivery": "disabled",
        "debug_verify_url": verify_url if email_verification_debug_return_url() else None,
    }

    if not smtp_enabled:
        print(f"[email-verification] SMTP disabled. Verify {email}: {verify_url}")
        result["delivery"] = "log_only"
        return result

    host = str(os.getenv("SMTP_HOST", "")).strip()
    port = int(os.getenv("SMTP_PORT", "587"))
    username = str(os.getenv("SMTP_USERNAME", "")).strip()
    password = str(os.getenv("SMTP_PASSWORD", "")).strip()
    use_tls = str(os.getenv("SMTP_USE_TLS", "true")).strip().lower() in ("1", "true", "yes", "on")

    if not host or not username or not password:
        print(f"[email-verification] SMTP config incomplete. Verify {email}: {verify_url}")
        result["delivery"] = "smtp_config_missing"
        return result

    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = f"{from_name} <{from_email}>"
    msg["To"] = email
    msg.set_content(
        f"""Verify your email address

Click this link to finish creating your account:

{verify_url}

This link expires in {email_verification_hours()} hours.

If you did not request this, you can ignore this email.
"""
    )

    msg.add_alternative(
        f"""\
<html>
  <body>
    <p>Verify your email address to finish creating your account.</p>
    <p><a href="{verify_url}">Verify email address</a></p>
    <p>This link expires in {email_verification_hours()} hours.</p>
    <p>If you did not request this, you can ignore this email.</p>
  </body>
</html>
""",
        subtype="html",
    )

    if use_tls:
        context = ssl.create_default_context()
        with smtplib.SMTP(host, port, timeout=20) as server:
            server.starttls(context=context)
            server.login(username, password)
            server.send_message(msg)
    else:
        with smtplib.SMTP(host, port, timeout=20) as server:
            server.login(username, password)
            server.send_message(msg)

    result["sent"] = True
    result["delivery"] = "smtp"
    return result
