# Optional Stretch Goals

This directory contains optional stretch-goal material for the Linux server
baseline lab. The required submission remains the Bash provisioning flow,
systemd service, Nginx frontend, validation script, hardening checklist,
evidence screenshots, and reboot proof.

## Contents

```text
bonus/
+-- ansible/                    Local Ansible equivalent
+-- docker/                     Optional Python backend container
+-- monitoring/                 Local health and host checks
+-- rollback/                   Dry-run-first uninstall workflow
+-- vm-snapshot-and-template/   Local snapshot and template notes
+-- README-BONUS-SECTION.md     Optional section for the main README
```

## Stretch Goal Map

| Assignment stretch goal | Bonus path |
|---|---|
| Ansible playbook equivalent | `bonus/ansible/playbook.yml` |
| Snapshot and restore instructions | `bonus/vm-snapshot-and-template/README.md` |
| Local VM template/export notes | `bonus/vm-snapshot-and-template/README.md` |
| Monitoring endpoint or node_exporter notes | `bonus/monitoring/` |
| Docker deployment of the demo service | `bonus/docker/` |
| Rollback or uninstall script | `bonus/rollback/` |

## Recommended Order

Run the required project first. Add bonus evidence only after provisioning,
validation, idempotency, and reboot survival have been captured.

## Quick Checks

```bash
bash -n bonus/monitoring/check-infra-demo.sh
bash -n bonus/docker/run-docker-demo.sh
bash -n bonus/rollback/uninstall-infra-demo.sh
sudo bash bonus/monitoring/check-infra-demo.sh
sudo bash bonus/rollback/uninstall-infra-demo.sh --dry-run
```

## Ansible

```bash
sudo apt-get update
sudo apt-get install -y ansible
ansible-playbook -i localhost, -c local bonus/ansible/playbook.yml --syntax-check
ansible-playbook -i localhost, -c local bonus/ansible/playbook.yml --check --diff
ansible-playbook -i localhost, -c local bonus/ansible/playbook.yml
sudo bash scripts/validate.sh
```

## Docker

```bash
docker --version
bash -n bonus/docker/run-docker-demo.sh
bash bonus/docker/run-docker-demo.sh
```

Docker is optional. Run it only if Docker is already installed or there is time
to install it safely in the local VM.

The Docker build uses the root `.dockerignore` to keep evidence screenshots,
Git metadata, and unrelated documentation out of the build context.

## Suggested Evidence

```text
evidence/bonus-ansible-check.png
evidence/bonus-monitoring-rollback-dryrun.png
evidence/bonus-docker-demo.png
```

Do not run rollback with `--execute` on the final submission VM unless the lab
is intentionally being removed after all evidence and demo work are complete.

## Demo Notes

For the main demo, keep the bonus proof short:

```bash
sudo bash bonus/monitoring/check-infra-demo.sh
sudo bash bonus/rollback/uninstall-infra-demo.sh --dry-run
```

Use Ansible and Docker screenshots only if time allows. The required evidence
still comes from provisioning, systemd service health, validation, hardening,
and reboot survival.
