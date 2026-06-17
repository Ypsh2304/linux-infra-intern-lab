#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed. Skip this optional stretch goal or install Docker first."
    exit 0
fi

IMAGE="infra-demo:bonus"
CONTAINER="infra-demo-bonus"

docker_cmd() {
    if docker info >/dev/null 2>&1; then
        docker "$@"
    else
        sudo docker "$@"
    fi
}

cleanup() {
    docker_cmd rm -f "$CONTAINER" >/dev/null 2>&1 || true
}

cleanup
docker_cmd build --pull -f bonus/docker/Dockerfile -t "$IMAGE" .
docker_cmd run -d --name "$CONTAINER" -p 18080:8080 "$IMAGE" >/dev/null
trap cleanup EXIT

sleep 2
curl -i http://127.0.0.1:18080/health
printf '\n'
curl -i http://127.0.0.1:18080/
docker_cmd logs "$CONTAINER" --tail 20
docker_cmd image inspect "$IMAGE" --format 'image_size_bytes={{.Size}}'
