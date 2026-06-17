# Optional Rollback / Uninstall

This stretch goal provides a dry-run-first rollback script for the infra-demo
lab. Do not run destructive rollback on the final submission VM before evidence
and demo recording are complete.

Safe evidence command:

```bash
bash -n bonus/rollback/uninstall-infra-demo.sh
sudo bash bonus/rollback/uninstall-infra-demo.sh --dry-run
```

Execute mode is intended for cleanup after submission:

```bash
sudo bash bonus/rollback/uninstall-infra-demo.sh --execute
```

The `--execute` mode requires typing `REMOVE-INFRA-DEMO` before it deletes anything.

The script removes lab-owned service files and lab-owned directories. It does
not remove the Git repository, user home directories, disks, partitions, or the
`linus` operational account.
