#!/bin/bash
#
# maintenance.sh
# Periodic housekeeping triggered by infra-maintenance.timer.
#
set -euo pipefail

LOG_DIR="${INFRA_DEMO_LOG_DIR:-/var/log/infra-demo}"
STATE_DIR="/var/lib/infra-demo"
PUBLIC_PORT="${INFRA_DEMO_PUBLIC_PORT:-80}"

mkdir -p "$STATE_DIR"

if [[ -d "$LOG_DIR" ]]; then
    find "$LOG_DIR" -type f -name '*.log' -mtime +7 -print -delete
else
    echo "log directory $LOG_DIR not found; skipping cleanup"
fi

snapshot="$STATE_DIR/last-snapshot.txt"
status_code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PUBLIC_PORT}/health" || echo "down")"

{
    printf 'timestamp=%s\n' "$(date -u +%FT%TZ)"
    printf 'public_health_status_code=%s\n' "$status_code"
} > "$snapshot"

echo "maintenance done; snapshot written to $snapshot"
