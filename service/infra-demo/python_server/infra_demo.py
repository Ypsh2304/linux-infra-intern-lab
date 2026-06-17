#!/usr/bin/env python3
"""Small HTTP health-check service for the infra-demo lab.

Configuration comes from environment variables injected by systemd through
EnvironmentFile=/etc/infra-demo/infra-demo.env.

The service is intentionally standard-library only. In this repo, nginx is
installed as the public HTTP entry point and reverse-proxies /health to this
Python service running on 127.0.0.1:8080.
"""

from __future__ import annotations

import json
import logging
import os
import signal
import sys
import threading
import time
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit


SERVICE_NAME = "infra-demo"
SERVICE_MESSAGE = "Hello from infra-demo local VM"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8080
DEFAULT_LOG_DIR = "/var/log/infra-demo"
LOG_FILE_NAME = "requests.log"

# Monotonic time is safer for uptime than wall-clock time because NTP or manual
# clock changes do not affect it.
START_TIME = time.monotonic()

logger = logging.getLogger(SERVICE_NAME)


@dataclass(frozen=True)
class AppConfig:
    """Runtime settings loaded from environment variables."""

    host: str
    port: int
    log_dir: Path

    @property
    def log_file(self) -> Path:
        return self.log_dir / LOG_FILE_NAME


def read_int_env(name: str, default: int) -> int:
    """Read an integer environment variable and fall back safely if invalid."""
    raw_value = os.environ.get(name)
    if raw_value is None or raw_value.strip() == "":
        return default

    try:
        return int(raw_value)
    except ValueError:
        print(
            f"Invalid {name}={raw_value!r}; using default {default}",
            file=sys.stderr,
            flush=True,
        )
        return default


def load_config() -> AppConfig:
    """Create the application config from INFRA_DEMO_* environment variables."""
    return AppConfig(
        host=os.environ.get("INFRA_DEMO_HOST", DEFAULT_HOST),
        port=read_int_env("INFRA_DEMO_PORT", DEFAULT_PORT),
        log_dir=Path(os.environ.get("INFRA_DEMO_LOG_DIR", DEFAULT_LOG_DIR)),
    )


def configure_logging(config: AppConfig) -> None:
    """Log to stdout for journald and to a bounded file under /var/log.

    journald is the primary service log because systemd captures stdout/stderr.
    The rotating file is kept for the assignment's log-file validation and for
    simple VM lab inspection.
    """
    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    logger.propagate = False

    formatter = logging.Formatter(
        fmt="%(asctime)s %(levelname)s %(name)s: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    try:
        config.log_dir.mkdir(parents=True, exist_ok=True)
        file_handler = RotatingFileHandler(
            config.log_file,
            maxBytes=1_000_000,
            backupCount=3,
            encoding="utf-8",
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except OSError as exc:
        # File logging is best-effort. journald/stdout still works.
        logger.warning("file logging disabled: %s", exc)


def health_payload() -> dict[str, Any]:
    """Build the JSON document returned by /health."""
    return {
        "status": "ok",
        "service": SERVICE_NAME,
        "message": SERVICE_MESSAGE,
        "uptime_seconds": round(time.monotonic() - START_TIME, 1),
    }


def landing_page() -> str:
    """Build the simple HTML page shown at /."""
    uptime = round(time.monotonic() - START_TIME, 1)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>infra-demo</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body {{ font-family: system-ui, sans-serif; margin: 2rem; line-height: 1.5; }}
    code {{ background: #f1f5f9; padding: 0.15rem 0.35rem; border-radius: 4px; }}
  </style>
</head>
<body>
  <h1>infra-demo is running</h1>
  <p><strong>{SERVICE_MESSAGE}</strong></p>
  <p>This page is served by the local VM through Nginx and the systemd-managed backend.</p>
  <p>Health endpoint: <code>/health</code></p>
  <p>Service uptime: <code>{uptime}s</code></p>
</body>
</html>
"""


class HealthHandler(BaseHTTPRequestHandler):
    """Request handler for the infra-demo health endpoint."""

    # Keep the Server header small and avoid exposing the Python version.
    server_version = f"{SERVICE_NAME}/1.0"
    sys_version = ""

    def do_GET(self) -> None:
        """Serve GET /health and return 404 for everything else."""
        path = urlsplit(self.path).path

        if path == "/":
            self.send_html(HTTPStatus.OK, landing_page())
            logger.info("GET / -> 200 from %s", self.client_ip)
            return

        if path != "/health":
            self.send_json(
                HTTPStatus.NOT_FOUND,
                {"status": "error", "message": "not found"},
            )
            logger.info("GET %s -> 404 from %s", path, self.client_ip)
            return

        self.send_json(HTTPStatus.OK, health_payload())
        logger.info("GET /health -> 200 from %s", self.client_ip)

    def do_HEAD(self) -> None:
        """Support HEAD /health for simple probes and load balancers."""
        path = urlsplit(self.path).path
        status = HTTPStatus.OK if path in {"/", "/health"} else HTTPStatus.NOT_FOUND

        self.send_response(status.value)
        content_type = "text/html; charset=utf-8" if path == "/" else "application/json; charset=utf-8"
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", "0")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

        logger.info("HEAD %s -> %s from %s", path, status.value, self.client_ip)

    @property
    def client_ip(self) -> str:
        """Return the remote IP address supplied by BaseHTTPRequestHandler."""
        return self.client_address[0]

    def send_json(self, status: HTTPStatus, payload: dict[str, Any]) -> None:
        """Serialize payload as JSON and send a complete HTTP response."""
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")

        self.send_response(status.value)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, status: HTTPStatus, body_text: str) -> None:
        """Send a small HTML response."""
        body = body_text.encode("utf-8")

        self.send_response(status.value)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format: str, *_args: object) -> None:
        """Disable the default stderr access log.

        Access logs are emitted explicitly in do_GET/do_HEAD so journald and the
        file handler use the same format.
        """
        return


def install_shutdown_handlers(server: ThreadingHTTPServer) -> None:
    """Handle systemd stop and Ctrl-C without risking a shutdown deadlock."""

    def request_shutdown(signum: int, _frame: object) -> None:
        signal_name = signal.Signals(signum).name
        logger.info("received %s; shutting down", signal_name)

        # socketserver.shutdown() must be called from a different thread while
        # serve_forever() is running. This keeps stop/restart reliable.
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, request_shutdown)
    signal.signal(signal.SIGINT, request_shutdown)


def run_server(config: AppConfig) -> None:
    """Create the HTTP server and block until systemd stops it."""
    server = ThreadingHTTPServer((config.host, config.port), HealthHandler)
    install_shutdown_handlers(server)

    logger.info("starting %s on %s:%s", SERVICE_NAME, config.host, config.port)

    try:
        server.serve_forever(poll_interval=0.5)
    finally:
        server.server_close()
        logger.info("%s stopped", SERVICE_NAME)


def main() -> None:
    """Program entry point."""
    config = load_config()
    configure_logging(config)
    run_server(config)


if __name__ == "__main__":
    main()
