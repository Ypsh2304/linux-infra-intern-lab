# Functional Requirement and Milestone Map

This document maps each assignment functional requirement to concrete files,
commands, and evidence. It also includes commit-message suggestions that mention
functional requirements without using short milestone labels.

## Functional requirement ownership by file

| FR | Covered by | Notes |
|---|---|---|
| FR1 - base setup | `scripts/provision.sh`: OS detection, apt package installation, timezone, ops user | Ubuntu 22.04/24.04 target, required packages, timezone, sudo user `linus`. |
| FR2 - service setup | `service/infra-demo/python_server/infra_demo.py`, `service/infra-demo/nginx_server/infra_demo.conf`, `systemd/infra-demo.service`, `scripts/provision.sh` | Python backend is systemd-managed; nginx is the public HTTP frontend. |
| FR3 - logs/config | `config/infra-demo.env`, journald, `/var/log/infra-demo`, `/var/log/nginx/infra-demo.*.log` | Env file is installed as `/etc/infra-demo/infra-demo.env` with mode 640. |
| FR4 - idempotency | `scripts/provision.sh` uses `install`, `ln -sfn`, service restarts, and existing-user checks | Prove by running `provision.sh` twice. |
| FR5 - hardening | `scripts/provision.sh`, `systemd/*.service`, `docs/hardening-checklist.md` | SSH safe defaults, UFW, unattended updates, file ownership, systemd sandboxing. |
| FR6 - local reprovisioning | `docs/local-vm-reprovisioning.md` | Snapshot/restore flow only; no cloud VM. |
| FR7 - validation | `scripts/validate.sh`, `docs/test-plan.md` | Checks service, HTTP, firewall, open ports, users, permissions, and logs. |
| FR8 - reboot survival | `scripts/validate.sh` before and after `sudo reboot` | Evidence goes under `evidence/final-reboot-validation.png` or equivalent terminal log. |

## Milestone evidence flow

### Base VM and repository setup

Evidence:

```bash
lsb_release -a
find . -maxdepth 4 -type f | sort
sudo bash scripts/provision.sh
id linus
```

### Service and systemd setup

Evidence:

```bash
systemctl status infra-demo --no-pager
systemctl status nginx --no-pager
curl -i http://127.0.0.1/nginx-check
curl -i http://127.0.0.1/health
curl -i http://127.0.0.1:8080/health
journalctl -u infra-demo -n 30 --no-pager
```

### Hardening and automation

Evidence:

```bash
ufw status verbose
sudo ss -ltnp
systemctl list-timers infra-maintenance.timer --no-pager
sudo stat -c '%U:%G %a %n' /etc/infra-demo/infra-demo.env
sudo bash scripts/provision.sh
```

### Validation and reboot testing

Evidence:

```bash
sudo bash scripts/validate.sh
sudo reboot
uptime
sudo bash scripts/validate.sh
```

### Cleanup, documentation, and demo

Evidence: final GitHub repo, demo video link, organized `evidence/` files.
