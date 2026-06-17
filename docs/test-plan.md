# Test Plan

`scripts/validate.sh` automates the minimum checks required by the assignment.
This document explains what each check proves and gives manual commands for
screenshots/evidence.

| Check area | What is verified | Manual command | Automated by |
|---|---|---|---|
| Service | `infra-demo`, `nginx`, and maintenance timer are enabled/active | `systemctl status infra-demo nginx`; `systemctl list-timers infra-maintenance.timer` | `validate.sh` |
| Health | Backend and nginx frontend return JSON health | `curl -i http://127.0.0.1:8080/health`; `curl -i http://127.0.0.1/health` | `validate.sh` |
| Firewall | UFW is active and only SSH/HTTP are exposed | `ufw status verbose`; `ss -ltnp` | `validate.sh` |
| Users | `linus` ops user and `infra-demo` service user exist | `id linus`; `id infra-demo`; `groups linus` | `validate.sh` |
| Permissions | Env file has safe ownership/mode | `stat -c '%U:%G %a %n' /etc/infra-demo/infra-demo.env` | `validate.sh` |
| Logs | Recent journald logs exist for infra-demo and nginx | `journalctl -u infra-demo -n 30 --no-pager`; `journalctl -u nginx -n 30 --no-pager` | `validate.sh` |
| Reboot | Services survive restart of the VM | `sudo reboot`; `uptime`; rerun validation | Manual + `validate.sh` |
| Idempotency | Provisioning can run twice safely | `sudo bash scripts/provision.sh` twice | Manual evidence |

## Demo sequence

1. Show local VM OS/version.
2. Show repo tree.
3. Run `sudo bash scripts/provision.sh`.
4. Run `curl -i http://127.0.0.1/health`.
5. Run `sudo bash scripts/validate.sh`.
6. Run `sudo bash scripts/provision.sh` again for idempotency evidence.
7. Reboot.
8. Run `uptime` and `sudo bash scripts/validate.sh` after reboot.

## Expected validation result

A healthy run should end with `0 failed`. The exact pass count may change if
extra checks are added, but any failure should be investigated before final
submission.


## Local VM IP note

Use `127.0.0.1` when testing from inside the VM. Use the local VM address from
`hostname -I | awk '{print $1}'` only when testing from the host machine or
recording the browser part of the demo.
