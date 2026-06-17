# Optional node_exporter Notes

node_exporter is the standard Prometheus exporter for Linux host metrics. It
exposes CPU, memory, disk, filesystem, and network metrics on port `9100`.

For this assignment, the primary monitoring proof remains local and simple:

- `curl http://127.0.0.1/`
- `curl http://127.0.0.1/nginx-check`
- `curl http://127.0.0.1/health`
- `systemctl status infra-demo nginx`
- `journalctl -u infra-demo`
- `systemctl list-timers infra-maintenance.timer`

node_exporter is documented as a future extension because the required evidence
already proves service health, logs, timer state, firewall state, and reboot
survival.
