# Optional Docker Packaging

This stretch goal packages the Python health backend as a local container. It
does not replace the required host deployment with systemd, Nginx, and UFW.

Run from the repository root:

```bash
docker --version
bash -n bonus/docker/run-docker-demo.sh
bash bonus/docker/run-docker-demo.sh
```

Optional Docker Engine install on Ubuntu Server:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run hello-world
```

The container maps host port `18080` to container port `8080`, so it does not
conflict with host Nginx on port `80` or the host backend on port `8080`.

The Dockerfile uses a small Python Alpine base image, avoids extra packages,
and runs the service as a non-root container user.

The build command uses `--pull` to refresh the base image when available. The
root `.dockerignore` keeps the build context small by excluding `.git`,
evidence screenshots, docs, logs, and unrelated bonus folders.
