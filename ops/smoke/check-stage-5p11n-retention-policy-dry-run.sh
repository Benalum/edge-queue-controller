#!/usr/bin/env bash

stage5p11n_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11N Retention Policy Dry-Run Smoke ==="

  echo
  echo "=== syntax checks ==="
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11N_RETENTION_POLICY_DRY_RUN_BEGIN" \
    "system_retention_dry_run" \
    "/system/retention/dry-run" \
    "AI_PLATFORM_FREE_DETAIL_RETENTION_DAYS" \
    "AI_PLATFORM_PAID_DETAIL_RETENTION_DAYS" \
    "study_session_events" \
    "web_power_policy_events" \
    "delete_enabled" \
    "dry_run"
  do
    if grep -R -Fq "$marker" edge_controller.py docs/stage-5p11n-retention-policy-dry-run.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== no deletion enabled in this stage ==="
  if grep -nE "DELETE FROM (study_session_events|study_sessions|study_reviews|jobs|job_results|web_presence|power_events|web_power_policy_events)" edge_controller.py | grep -v "retention dry-run" >/tmp/stage5p11n-delete-check.txt; then
    echo "FAIL destructive deletion found"
    cat /tmp/stage5p11n-delete-check.txt
    ok=0
  else
    echo "OK no destructive retention delete statements"
  fi

  echo
  echo "=== local dry-run function smoke ==="
  "$PYBIN" - <<'PY'
import edge_controller as ec

result = ec._retention_plan_rows()
assert result["ok"] is True, result
assert result["mode"] == "dry_run", result
assert result["policy"]["free_detail_retention_days"] == 7, result["policy"]
assert result["policy"]["paid_detail_retention_days"] >= 30, result["policy"]
assert result["policy"]["delete_enabled"] is False, result["policy"]

tables = {item["table"]: item for item in result["tables"]}
for name in [
    "study_session_events",
    "study_sessions",
    "study_reviews",
    "jobs",
    "job_results",
    "web_presence",
    "power_events",
    "web_power_policy_events",
]:
    assert name in tables, name
    assert "eligible_rows" in tables[name], tables[name]

print("OK retention dry-run tables", sorted(tables))
PY
  if [ "$?" = "0" ]; then
    echo "OK local dry-run function"
  else
    echo "FAIL local dry-run function"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11n-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /profile /admin /system /study /companion; do
    code="$(curl -sS -L -o /tmp/stage5p11n-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11n-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11N_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11N_SMOKE_FAIL"
  return 1
}

if stage5p11n_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
