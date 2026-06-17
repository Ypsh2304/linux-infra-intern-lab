#!/usr/bin/env bash
set -uo pipefail

section() { printf '\n== %s ==\n' "$1"; }

passed=0
failed=0

check() {
    local label="$1"; shift
    if "$@"; then
        printf '[PASS] %s\n' "$label"
        passed=$((passed + 1))
    else
        printf '[FAIL] %s\n' "$label"
        failed=$((failed + 1))
    fi
}

section "service states"
check "infra-demo active" systemctl is-active --quiet infra-demo
check "nginx active" systemctl is-active --quiet nginx
check "maintenance timer active" systemctl is-active --quiet infra-maintenance.timer

section "HTTP checks"
check "Nginx direct check responds" curl -fsS http://127.0.0.1/nginx-check
check "Nginx landing page responds" curl -fsS http://127.0.0.1/
check "Nginx /health responds" curl -fsS http://127.0.0.1/health
check "backend /health responds" curl -fsS http://127.0.0.1:8080/health

section "listening ports"
ss -ltn | awk 'NR == 1 || /:80 / || /127\.0\.0\.1:8080/'

section "timer"
systemctl list-timers infra-maintenance.timer --no-pager

section "recent logs"
journalctl -u infra-demo -n 8 --no-pager

section "firewall"
if command -v ufw >/dev/null 2>&1; then
  ufw status verbose
else
    echo "ufw not installed"
fi

printf '\nsummary: %s passed, %s failed\n' "$passed" "$failed"
[[ "$failed" -eq 0 ]]
