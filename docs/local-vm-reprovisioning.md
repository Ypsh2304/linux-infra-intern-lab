# Local VM Reprovisioning Flow (FR6)

The assignment requires a local VM only. Use VMware Workstation, VirtualBox,
Hyper-V, UTM, or another local hypervisor. Do not use AWS, Azure, GCP,
DigitalOcean, Linode, Oracle Cloud, or any other cloud VM.

## 1. Create the clean base VM

1. Create a new Ubuntu Server 22.04/24.04 LTS VM.
2. Select OpenSSH server during installation.
3. Log in through the VM console.
4. Install only the minimum tools needed to clone the repo:

   ```bash
   sudo apt-get update
   sudo apt-get install -y git
   ```

5. Take a local hypervisor snapshot named something like:

   ```text
   clean-base-before-infra-demo
   ```

This snapshot is the clean starting point for the reprovisioning proof.

## 2. First provisioning run

```bash
git clone <your-repo-url> linux-infra-intern-assignment
cd linux-infra-intern-assignment
sudo bash scripts/provision.sh
sudo bash scripts/validate.sh
```

Capture evidence for provisioning, service status, health endpoint, firewall,
and validation output.

## 3. Reprovision from clean state

1. Restore the clean local snapshot.
2. Boot the VM again.
3. Clone or copy the repo again.
4. Rerun:

   ```bash
   cd linux-infra-intern-assignment
   sudo bash scripts/provision.sh
   sudo bash scripts/validate.sh
   ```

This proves the setup is reproducible from a known local VM state.

## 4. Idempotency rerun on the same VM

After one successful provisioning run, run it again without restoring the
snapshot:

```bash
sudo bash scripts/provision.sh
sudo bash scripts/validate.sh
```

The script should not duplicate users, break systemd units, or expose extra
ports. It should redeploy files safely and restart services cleanly.

## 5. Reboot survival evidence

```bash
sudo reboot
# log back in
cd linux-infra-intern-assignment
uptime
sudo bash scripts/validate.sh
```

Save the final screenshot as:

```text
evidence/final-reboot-validation.png
```
