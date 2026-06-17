# Troubleshooting

## `provision.sh` says `run with sudo`

Run it as root through sudo:

```bash
sudo bash scripts/provision.sh
```

The script installs packages, writes under `/etc`, configures systemd, creates
users, and updates firewall rules, so root privileges are required.

## nginx health works but backend health fails

Check the Python service:

```bash
systemctl status infra-demo --no-pager
journalctl -u infra-demo -n 50 --no-pager
curl -i http://127.0.0.1:8080/health
```

Common causes: `/opt/infra-demo/python_server/infra_demo.py` missing, bad environment file, or
port 8080 already in use.

## Backend health works but nginx health fails

Check nginx:

```bash
sudo /usr/sbin/nginx -t
systemctl status nginx --no-pager
journalctl -u nginx -n 50 --no-pager
curl -i http://127.0.0.1/health
```

If `/usr/sbin/nginx -t` fails, inspect `/etc/nginx/sites-enabled/infra-demo.conf`.
Rerunning `sudo bash scripts/provision.sh` redeploys the site file.

If `sudo nginx -t` says `command not found`, use the full path:

```bash
sudo /usr/sbin/nginx -t
```

## `ufw` asks about disrupting SSH

The provisioning script uses `ufw --force enable` and allows OpenSSH before
enabling UFW. If running manually, always allow SSH first:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw enable
```

## Locked out of SSH after hardening

Open the VM console from the local hypervisor. Console access does not depend
on SSH or UFW. Inspect the SSH drop-in:

```bash
sudo cat /etc/ssh/sshd_config.d/99-infra-demo-hardening.conf
sudo sshd -t
sudo systemctl reload ssh
```

This lab does not disable password authentication by default.

## `validate.sh` fails the loopback-only backend check

Confirm the env file has:

```text
INFRA_DEMO_HOST=127.0.0.1
INFRA_DEMO_PORT=8080
```

Then restart the service:

```bash
sudo systemctl restart infra-demo
sudo ss -ltnp | grep 8080
```

The backend should listen on `127.0.0.1:8080`, not `0.0.0.0:8080`.

## Maintenance timer has not run yet

It runs 5 minutes after boot and then every 15 minutes:

```bash
systemctl list-timers infra-maintenance.timer --no-pager
sudo systemctl start infra-maintenance.service
sudo cat /var/lib/infra-demo/last-snapshot.txt
```

## Should validate.sh run automatically after reboot?

No. The assignment asks you to prove reboot survival by rebooting the VM,
logging back in, showing `uptime`, and running `sudo bash scripts/validate.sh`
again. The systemd-managed services start automatically; the validation script
is a manual proof command for your evidence screenshot/video.

```bash
sudo reboot
# log back in after boot
cd ~/linux-infra-intern-lab
uptime
sudo bash scripts/validate.sh
```
