#!/bin/bash
#
# provision.sh
# Reproducible baseline provisioning for the infra-demo local VM lab.
#
# Run from the repository root inside the VM:
#   sudo bash scripts/provision.sh
#
# Functional requirement coverage:
#   FR1 - OS detection, package index update, packages, timezone, ops user
#   FR2 - Python health service + nginx frontend, both managed by systemd
#   FR3 - environment file, journald logs, controlled log directories
#   FR4 - idempotent reruns: safe install/copy/reload operations
#   FR5 - SSH defaults, UFW firewall, unattended updates, safe ownership/modes
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# ---- lab settings -----------------------------------------------------------
OPS_USER="linus"
SVC_USER="infra-demo"
SVC="infra-demo"
MAINT="infra-maintenance"
TIMEZONE="Asia/Kolkata"

APP_DIR="/opt/${SVC}"
PY_APP_DIR="${APP_DIR}/python_server"

CONF_DIR="/etc/${SVC}"
STATE_DIR="/var/lib/${SVC}"

LOG_DIR="/var/log/${SVC}"

NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/${SVC}.conf"
NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/${SVC}.conf"

PYTHON_SRC="${REPO_ROOT}/service/infra-demo/python_server/infra_demo.py"

NGINX_SRC="${REPO_ROOT}/service/infra-demo/nginx_server/infra_demo.conf"
PKGS=(curl git tree python3 ufw unattended-upgrades openssh-server nginx)

log() { printf '\n[provision] %s\n' "$1"; }
warn() { printf '[provision] WARNING: %s\n' "$1" >&2; }
die() { printf '[provision] ERROR: %s\n' "$1" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "run with sudo: sudo bash scripts/provision.sh"

require_repo_file() {
    local path="$1"
    [[ -f "$path" ]] || die "missing required repository file: $path"
}

preflight_repo() {
    log "checking repository files"
    require_repo_file "$PYTHON_SRC"
    require_repo_file "$REPO_ROOT/config/infra-demo.env"
    require_repo_file "$NGINX_SRC"
    require_repo_file "$REPO_ROOT/systemd/${SVC}.service"
    require_repo_file "$REPO_ROOT/systemd/${MAINT}.service"
    require_repo_file "$REPO_ROOT/systemd/${MAINT}.timer"
    require_repo_file "$REPO_ROOT/scripts/maintenance.sh"
}

# -----------------------------------------------------------------------------
# FR1: base setup
# -----------------------------------------------------------------------------

detect_os() {
    [[ -r /etc/os-release ]] || die "/etc/os-release missing"
    # shellcheck disable=SC1091
    . /etc/os-release

    log "OS: ${PRETTY_NAME}"

    if [[ "$ID" != "ubuntu" ]]; then
        die "this script targets Ubuntu Server 22.04/24.04 LTS; detected ID=${ID}"
    fi

    case "${VERSION_ID:-unknown}" in
        22.04|24.04) ;;
        *) warn "tested on Ubuntu 22.04/24.04 LTS; detected VERSION_ID=${VERSION_ID:-unknown}" ;;
    esac
}

run_apt_with_retry() {
    local description="$1"
    shift

    log "$description"
    if ! "$@"; then
        warn "$description failed once; retrying after 5 seconds"
        sleep 5
        "$@"
    fi
}

install_base_packages() {
    run_apt_with_retry "updating apt package index" apt-get update -qq

    log "installing packages: ${PKGS[*]}"
    DEBIAN_FRONTEND=noninteractive     NEEDRESTART_MODE=a     apt-get install -y "${PKGS[@]}"
}

set_timezone() {
    log "setting timezone to ${TIMEZONE}"
    timedatectl set-timezone "$TIMEZONE"
}

create_ops_user() {
    if id "$OPS_USER" >/dev/null 2>&1; then
        log "ops user '${OPS_USER}' already exists"
    else
        log "creating ops sudo user '${OPS_USER}'"
        adduser --disabled-password --gecos "Ops user" "$OPS_USER"
    fi

    usermod -aG sudo "$OPS_USER"
}

# -----------------------------------------------------------------------------
# FR2 + FR3: app, nginx, config, logs, systemd units
# -----------------------------------------------------------------------------

create_service_account() {
    if id "$SVC_USER" >/dev/null 2>&1; then
        log "service account '${SVC_USER}' already exists"
    else
        log "creating no-login service account '${SVC_USER}'"
        useradd --system --no-create-home --shell /usr/sbin/nologin "$SVC_USER"
    fi
}

create_directories() {
    log "creating application, config, state, and log directories"
    install -d -m 0755 -o root        -g root        "$APP_DIR"
    install -d -m 0755 -o root        -g root        "$PY_APP_DIR"
    install -d -m 0750 -o root        -g "$SVC_USER" "$CONF_DIR"
    install -d -m 0750 -o "$SVC_USER" -g "$SVC_USER" "$STATE_DIR"
    install -d -m 0750 -o "$SVC_USER" -g "$SVC_USER" "$LOG_DIR"
}

deploy_config() {
    log "deploying environment file to ${CONF_DIR}/infra-demo.env"
    install -m 0640 -o root -g "$SVC_USER" \
        "$REPO_ROOT/config/infra-demo.env" "${CONF_DIR}/infra-demo.env"
}

deploy_app() {
    log "deploying Python health service"
    install -m 0755 -o root -g root \
        "$PYTHON_SRC" "${PY_APP_DIR}/infra_demo.py"
}

deploy_systemd_units() {
    log "installing systemd service and timer units"
    install -m 0644 -o root -g root "$REPO_ROOT/systemd/${SVC}.service"   /etc/systemd/system/
    install -m 0644 -o root -g root "$REPO_ROOT/systemd/${MAINT}.service" /etc/systemd/system/
    install -m 0644 -o root -g root "$REPO_ROOT/systemd/${MAINT}.timer"   /etc/systemd/system/
    install -m 0755 -o root -g root "$REPO_ROOT/scripts/maintenance.sh"   "/usr/local/sbin/${MAINT}.sh"

    systemd-analyze verify "/etc/systemd/system/${SVC}.service" \
        "/etc/systemd/system/${MAINT}.service" \
        "/etc/systemd/system/${MAINT}.timer"

    systemctl daemon-reload
    systemctl enable --now "${SVC}.service"
    systemctl restart "${SVC}.service"
    systemctl enable --now "${MAINT}.timer"
    systemctl restart "${MAINT}.timer"
}

deploy_nginx() {
    log "configuring nginx reverse proxy on port 80"
    install -m 0644 -o root -g root \
        "$NGINX_SRC" "$NGINX_SITE_AVAILABLE"

    # Disable the default welcome site so this lab owns the HTTP root.
    rm -f /etc/nginx/sites-enabled/default
    ln -sfn "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"

    nginx -t
    systemctl enable --now nginx
    systemctl reload nginx || systemctl restart nginx
}

# -----------------------------------------------------------------------------
# FR5: hardening
# -----------------------------------------------------------------------------

harden_ssh() {
    log "applying SSH hardening drop-in"

    # PasswordAuthentication remains enabled for a fresh local VM where no SSH
    # key may be installed yet. See docs/hardening-checklist.md for the reason.
    cat > /etc/ssh/sshd_config.d/99-infra-demo-hardening.conf <<'EOF'
PermitRootLogin no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
LoginGraceTime 30
EOF

    sshd -t || die "sshd config test failed; not reloading ssh"
    systemctl reload ssh
}

harden_firewall() {
    log "configuring UFW firewall"

    ufw default deny incoming
    ufw default allow outgoing
    ufw allow OpenSSH

    # nginx is the public HTTP entry point. The Python service is bound to
    # 127.0.0.1:8080, so port 8080 is deliberately not exposed in UFW.
    if ufw app list | grep -qx '  Nginx HTTP'; then
        ufw allow 'Nginx HTTP'
    else
        ufw allow 80/tcp
    fi

    # If an older run opened the backend port directly, remove that rule.
    local backend_port
    backend_port="$(grep -E '^INFRA_DEMO_PORT=' "${CONF_DIR}/infra-demo.env" | cut -d= -f2)"
    if [[ "$backend_port" =~ ^[0-9]+$ ]]; then
        ufw --force delete allow "${backend_port}/tcp" >/dev/null 2>&1 || true
    fi

    ufw --force enable
}

harden_updates() {
    log "enabling unattended security updates"
    systemctl enable --now unattended-upgrades
}

main() {
    preflight_repo

    # FR1: base OS and operational user setup
    detect_os
    install_base_packages
    set_timezone
    create_ops_user

    # FR2/FR3: service, config, logs, nginx, and systemd setup
    create_service_account
    create_directories
    deploy_config
    deploy_app
    deploy_systemd_units
    deploy_nginx

    # FR5: basic hardening and automatic security updates
    harden_ssh
    harden_firewall
    harden_updates

    log "done - run 'sudo bash scripts/validate.sh' to verify"
}

main "$@"
