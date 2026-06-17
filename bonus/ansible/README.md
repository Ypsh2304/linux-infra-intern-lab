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
- timezone setup
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

Implementation notes:

- Uses `ansible.builtin.*` module names for clarity.
- Uses `ansible.builtin.apt` with cache age and lock timeout options.
- Uses `ansible.builtin.systemd_service` for systemd unit management.
- Uses built-in modules where practical and simple commands where the base VM
  does not need extra Ansible collections.
