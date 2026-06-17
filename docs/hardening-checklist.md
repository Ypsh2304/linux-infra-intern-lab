# Hardening Checklist

This checklist documents what was applied, why it was applied, and what was
intentionally skipped for safety in a local VM lab.

## Applied controls

| Control | Location | Why |
|---|---|---|
| Non-root sudo user `linus` | `scripts/provision.sh` | Avoids routine root login while keeping admin capability through sudo. |
| Dedicated no-login service account `infra-demo` | `scripts/provision.sh` | The Python service does not need a shell or human login. |
| Python backend bound to `127.0.0.1:8080` | `config/infra-demo.env` | Keeps the app backend private; nginx is the only public HTTP entry point. |
| nginx public HTTP frontend on port 80 | `service/infra-demo/nginx_server/infra_demo.conf` | Provides a standard web-server layer while preserving the required systemd app service. |
| UFW default deny incoming, allow outgoing | `scripts/provision.sh` | Establishes a small network surface. |
| UFW allows OpenSSH and HTTP only | `scripts/provision.sh` | SSH is required for admin access; nginx serves the health endpoint. |
| SSH `PermitRootLogin no` | `/etc/ssh/sshd_config.d/99-infra-demo-hardening.conf` | Prevents direct root SSH login. |
| SSH `PermitEmptyPasswords no` | same | Blocks empty-password authentication. |
| SSH `X11Forwarding no` | same | Not needed on a headless lab server. |
| SSH `MaxAuthTries 3` and `LoginGraceTime 30` | same | Reduces noisy brute-force attempt windows. |
| `sshd -t` before SSH reload | `scripts/provision.sh` | Prevents applying a broken SSH config. |
| Unattended security updates | `unattended-upgrades` | Keeps security updates enabled on the VM. |
| Env file mode `640`, owner `root:infra-demo` | `scripts/provision.sh` | Service can read config; unrelated users cannot. |
| Controlled app/state/log directories | `/opt`, `/var/lib`, `/var/log` paths | Clear ownership and predictable validation. |
| systemd sandboxing | `systemd/infra-demo.service`, `systemd/infra-maintenance.service` | Limits writable paths and privilege escalation. |
| Absolute `ExecStart` paths | systemd unit files | Avoids PATH confusion and keeps execution auditable. |
| nginx security headers | `service/infra-demo/nginx_server/infra_demo.conf` | Adds simple defensive headers without extra dependencies. |

## Intentionally not applied

| Control | Why skipped |
|---|---|
| `PasswordAuthentication no` | A fresh local VM may not have SSH keys installed. Disabling passwords without confirmed console/key recovery can lock out the evaluator. |
| `AllowUsers linus` | Could lock out the installer/default account on some VM setups. Safer to document as a next step. |
| Changing SSH port | Adds usability cost and little real hardening in a local-only lab. |
| TLS/HTTPS for nginx | This is a local VM lab; adding self-signed cert handling would distract from the assignment's Linux/systemd focus. |
| fail2ban | Useful for internet-facing servers, but out of scope for a local VM baseline. |
| Full disk encryption | Must be chosen during VM/OS installation, not safely applied by a provisioning script afterward. |
| Disabling core Ubuntu services | The assignment says disable unused services where safe. No clearly unused enabled service is installed by this lab beyond the intentionally required ones. |

## Post-lab next steps

After confirming SSH key access from the host machine, the next safe hardening
step would be:

```bash
sudo install -m 0644 -o root -g root /dev/null /etc/ssh/sshd_config.d/100-key-only.conf
printf 'PasswordAuthentication no\n' | sudo tee /etc/ssh/sshd_config.d/100-key-only.conf
sudo sshd -t
sudo systemctl reload ssh
```

Only do this after proving you can still log in through SSH keys or VM console.
