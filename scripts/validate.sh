#!/bin/bash
#
# validate.sh
# Validation script for FR7 and FR8.
#
# It intentionally does not use `set -e`: every check runs even if an earlier
# check fails, so the final output gives a complete troubleshooting picture.
#
# Usage:
#   sudo bash scripts/validate.sh
#
set -uo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "run with sudo: sudo bash scripts/validate.sh"; exit 1; }

SVC="infra-demo"
MAINT_TIMER="infra-maintenance.timer"
SVC_USER="infra-demo"
OPS_USER="linus"
ENV_FILE="/etc/infra-demo/infra-demo.env"
NGINX_SITE="/etc/nginx/sites-enabled/infra-demo.conf"

PORT="$(grep -E '^INFRA_DEMO_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2)"
PORT="${PORT:-8080}"
PUBLIC_PORT="$(grep -E '^INFRA_DEMO_PUBLIC_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2)"
PUBLIC_PORT="${PUBLIC_PORT:-80}"

passed=0
failed=0
LAST_LOG="/tmp/infra-demo-validate-last.log"

check() {
    local label="$1"
    shift

    if "$@" >"$LAST_LOG" 2>&1; then
        printf '[PASS] %s\n' "$label"
        passed=$((passed + 1))
    else
        printf '[FAIL] %s\n' "$label"
        sed 's/^/       /' "$LAST_LOG"
        failed=$((failed + 1))
    fi
}

section() {
    printf '\n== %s ==\n' "$1"
}

section "systemd services"
check "infra-demo.service is enabled"       systemctl is-enabled --quiet "$SVC"
check "infra-demo.service is active"        systemctl is-active --quiet "$SVC"
check "nginx.service is enabled"            systemctl is-enabled --quiet nginx
check "nginx.service is active"             systemctl is-active --quiet nginx
check "infra-maintenance.timer is enabled"  systemctl is-enabled --quiet "$MAINT_TIMER"
check "infra-maintenance.timer is active"   systemctl is-active --quiet "$MAINT_TIMER"

section "HTTP health"
check "backend /health returns JSON status" \
    bash -c "curl -sf http://127.0.0.1:${PORT}/health | grep -q '\"status\":\"ok\"'"
check "nginx /health reverse proxy returns JSON status" \
    bash -c "curl -sf http://127.0.0.1:${PUBLIC_PORT}/health | grep -q '\"service\":\"infra-demo\"'"

section "network and firewall"
check "backend port ${PORT} listens on loopback only" \
    bash -c "ss -ltn | awk '{print \$4}' | grep -qx '127.0.0.1:${PORT}'"
check "nginx public port ${PUBLIC_PORT} is listening" \
    bash -c "ss -ltn | awk '{print \$4}' | grep -Eq '(^0\.0\.0\.0:${PUBLIC_PORT}$|^\[::\]:${PUBLIC_PORT}$)'"
check "UFW is active" \
    bash -c "ufw status | grep -q 'Status: active'"
check "UFW allows SSH" \
    bash -c "ufw status | grep -Eiq '(OpenSSH|22/tcp).*ALLOW'"
check "UFW allows nginx/http" \
    bash -c "ufw status | grep -Eiq '(Nginx HTTP|80/tcp).*ALLOW'"

section "users"
check "ops user '${OPS_USER}' exists"      id "$OPS_USER"
check "'${OPS_USER}' is in sudo group"     bash -c "groups ${OPS_USER} | grep -qw sudo"
check "service user '${SVC_USER}' exists"  id "$SVC_USER"

section "permissions and config"
check "env file is root:${SVC_USER} mode 640" \
    bash -c "stat -c '%U:%G %a' '${ENV_FILE}' | grep -qx 'root:${SVC_USER} 640'"
check "nginx site is installed" \
    test -L "$NGINX_SITE"
check "nginx config syntax is valid" \
    nginx -t

section "SSH hardening"
check "PermitRootLogin is disabled" \
    bash -c "sshd -T 2>/dev/null | grep -qi '^permitrootlogin no'"
check "empty SSH passwords are disabled" \
    bash -c "sshd -T 2>/dev/null | grep -qi '^permitemptypasswords no'"

section "logs"
check "recent infra-demo journal entries exist" \
    bash -c "journalctl -u ${SVC} --no-pager -n 30 --since '-1 hour' --output=cat | grep -q ."
check "infra-demo request log contains health request" \
    bash -c "test -s /var/log/infra-demo/requests.log && tail -n 50 /var/log/infra-demo/requests.log | grep -q 'GET /health -> 200'"
check "nginx access log contains health request" \
    bash -c "test -s /var/log/nginx/infra-demo.access.log && tail -n 50 /var/log/nginx/infra-demo.access.log | grep -q 'GET /health'"
check "recent nginx journal entries are readable" \
    bash -c "journalctl -u nginx --no-pager -n 30 --output=cat >/dev/null"

printf '\nuptime: %s\n' "$(uptime)"
printf 'summary: %s passed, %s failed\n' "$passed" "$failed"

[[ "$failed" -eq 0 ]]
