#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---dry-run}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--execute" ]]; then
  echo "Usage: sudo bash bonus/rollback/uninstall-infra-demo.sh [--dry-run|--execute]" >&2
  exit 2
fi

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

run_cmd() {
  echo "+ $*"
  if [[ "$MODE" == "--execute" ]]; then
    "$@"
  fi
}

cat <<'MSG'
This rollback script is scoped to the infra-demo lab only.
It may remove:
- infra-demo and infra-maintenance systemd unit files
- nginx infra-demo site config and symlink
- /opt/infra-demo
- /etc/infra-demo
- /var/lib/infra-demo
- /var/log/infra-demo
It does not remove your Git repository, disks, partitions, user homes, or unrelated host data.
MSG

if [[ "$MODE" == "--dry-run" ]]; then
  echo "DRY RUN ONLY: commands will be printed, not executed."
else
  read -r -p "Type REMOVE-INFRA-DEMO to continue: " confirm
  [[ "$confirm" == "REMOVE-INFRA-DEMO" ]] || { echo "cancelled"; exit 0; }
fi

run_cmd systemctl disable --now infra-maintenance.timer
run_cmd systemctl disable --now infra-demo.service
run_cmd rm -f /etc/systemd/system/infra-demo.service
run_cmd rm -f /etc/systemd/system/infra-maintenance.service
run_cmd rm -f /etc/systemd/system/infra-maintenance.timer
run_cmd rm -f /etc/nginx/sites-enabled/infra-demo.conf
run_cmd rm -f /etc/nginx/sites-available/infra-demo.conf
run_cmd systemctl daemon-reload
run_cmd rm -rf /opt/infra-demo /etc/infra-demo /var/lib/infra-demo /var/log/infra-demo

echo "Rollback ${MODE} complete."
