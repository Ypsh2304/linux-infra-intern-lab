# Optional Monitoring Checks

This stretch goal keeps monitoring local and lightweight. It does not install a
Prometheus stack. It provides a runnable check script and documents where
node_exporter could fit in a larger environment.

Run from the repository root:

```bash
bash -n bonus/monitoring/check-infra-demo.sh
sudo bash bonus/monitoring/check-infra-demo.sh
```

The script checks:

- `infra-demo.service`
- `nginx.service`
- `infra-maintenance.timer`
- the Nginx landing page at `/`
- the public health endpoint at `/health`
- the backend health endpoint at `127.0.0.1:8080/health`
- listening ports, recent logs, and UFW status

Suggested evidence:

```text
evidence/bonus-monitoring-rollback-dryrun.png
```

`node-exporter-notes.md` is documentation-only. It explains the next monitoring
step without adding unnecessary runtime scope to the assignment VM.
