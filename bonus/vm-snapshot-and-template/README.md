# Optional Local VM Snapshot and Template Notes

Use only a local hypervisor such as VMware Workstation/Player, VirtualBox,
Hyper-V, or UTM. Do not use a cloud VM.

Suggested VMware evidence flow:

1. Create or open the Ubuntu VM locally.
2. Before provisioning, take a snapshot named `clean-before-provisioning`.
3. Clone or pull the GitHub repository inside the VM.
4. Run `sudo bash scripts/provision.sh`.
5. Run `sudo bash scripts/validate.sh`.
6. Reboot and run validation again.
7. Optional: restore the clean snapshot and repeat the provisioning flow.

Suggested screenshot:

```text
evidence/bonus-vm-snapshot.png
```

Optional local VM template/export note:

- In VMware Workstation Pro, export can be done from the UI using `File -> Export to OVF` when supported.
- Keep export/template work documentation-only unless the required repository,
  evidence screenshots, and demo video are already complete.
