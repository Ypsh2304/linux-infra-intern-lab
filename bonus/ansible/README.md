# Optional Ansible Equivalent

This playbook mirrors the Bash provisioning flow for the local Ubuntu VM. It is
a stretch goal only and does not replace `scripts/provision.sh`.

Run from the repository root:

```bash
sudo apt-get update
sudo apt-get install -y ansible
ansible-playbook -i localhost, -c local bonus/ansible/playbook.yml --check --diff
ansible-playbook -i localhost, -c local bonus/ansible/playbook.yml
sudo bash scripts/validate.sh
```

What it covers:

- package installation
- `linus` operational user
- `infra-demo` service user
- service directories and config
- systemd service and timer
- Nginx reverse proxy
- SSH hardening drop-in
- UFW rules
- apt daily update timers

Suggested evidence:

```text
evidence/bonus-ansible-check.png
```

The `--check --diff` run shows planned changes. The apply run changes the local
VM. `scripts/validate.sh` remains the final proof.
