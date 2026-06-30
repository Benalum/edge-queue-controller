#!/usr/bin/env bash
set -euo pipefail

ENV_EXAMPLE=".env.example"
ROBOTS="frontend/wrapper-ui/robots.txt"
DOC="docs/stage-17k-z-r8l-source-email-domain-config-no-runtime.md"
DNS_OBS="docs/generated/stage-17k-z-r8l-public-email-dns-observation.txt"

echo "=== Stage 17K-Z-R8L-R2 source email/domain config smoke ==="

test -f "$ENV_EXAMPLE"
test -f "$ROBOTS"
test -f "$DOC"
test -f "$DNS_OBS"

grep -Fq "PUBLIC_BASE_URL=https://buddieswhostudy.com" "$ENV_EXAMPLE"
grep -Fq "EMAIL_FROM=no-reply@buddieswhostudy.com" "$ENV_EXAMPLE"
grep -Fq "EMAIL_FROM_NAME=Buddies Who Study" "$ENV_EXAMPLE"
grep -Fq "Sitemap: https://buddieswhostudy.com/sitemap.xml" "$ROBOTS"

if grep -Fq "PUBLIC_BASE_URL=https://alexhartel.com" "$ENV_EXAMPLE"; then
  echo "REFUSE: old PUBLIC_BASE_URL remains in .env.example"
  exit 1
fi

if grep -Fq "EMAIL_FROM=no-reply@alexhartel.com" "$ENV_EXAMPLE"; then
  echo "REFUSE: old EMAIL_FROM remains in .env.example"
  exit 1
fi

grep -Fq "Stage 17K-Z-R8L-R2" "$DOC"
grep -Fq "no-reply@buddieswhostudy.com" "$DOC"
grep -Fq "This stage does not update live CT203 environment variables." "$DOC"

grep -Fq "buddieswhostudy.com TXT" "$DNS_OBS"
grep -Fq "_dmarc.buddieswhostudy.com TXT" "$DNS_OBS"

echo "PASS Stage 17K-Z-R8L-R2 source email/domain config smoke"
