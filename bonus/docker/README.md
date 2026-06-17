# Optional Docker Packaging

This stretch goal packages the Python health backend as a local container. It
does not replace the required host deployment with systemd, Nginx, and UFW.

Run from the repository root:

```bash
docker --version
bash -n bonus/docker/run-docker-demo.sh
bash bonus/docker/run-docker-demo.sh
```

The container maps host port `18080` to container port `8080`, so it does not
conflict with host Nginx on port `80` or the host backend on port `8080`.

The Dockerfile uses a small Python Alpine base image, avoids extra packages,
and runs the service as a non-root container user.

The build command uses `--pull` to refresh the base image when available. The
root `.dockerignore` keeps the build context small by excluding `.git`,
evidence screenshots, docs, logs, and unrelated bonus folders.

Suggested evidence:

```text
evidence/bonus-docker-demo.png
```
