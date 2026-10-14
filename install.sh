#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LAUNCHER_SOURCE="$SCRIPT_DIR/ubuntu-26.04-budgie.sh"
readonly LAUNCHER_TARGET="/usr/local/bin/budgie26"

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

os_value() {
    local key="$1"
    [[ -r /etc/os-release ]] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s\n' "${!key:-}"
}

[[ "$(id -u)" -ne 0 ]] || die "Run this installer as your normal Ubuntu user, not as root."
grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || die "This installer must be run inside WSL2."
[[ "$(os_value ID 2>/dev/null || true)" == "ubuntu" ]] || die "This installer requires Ubuntu."
[[ "$(os_value VERSION_ID 2>/dev/null || true)" == "26.04" ]] || die "This installer requires Ubuntu 26.04."
[[ -f "$LAUNCHER_SOURCE" ]] || die "Missing $LAUNCHER_SOURCE"

if [[ "$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')" != "systemd" ]]; then
    printf 'Native WSL systemd is not active yet.\n'
    bash "$SCRIPT_DIR/ubuntu-26.04-systemd.sh" --enable
    printf '\nClose Ubuntu, run "wsl --shutdown" in Windows PowerShell,\n'
    printf 'then open Ubuntu and run "bash install.sh" again.\n'
    exit 2
fi

printf 'Installing Ubuntu Budgie and the WSLg launcher...\n'
sudo apt-get update
sudo apt-get install -y \
    ubuntu-budgie-desktop \
    labwc \
    xwayland \
    dbus-daemon \
    wlr-randr \
    mesa-utils

sudo install -o root -g root -m 0755 "$LAUNCHER_SOURCE" "$LAUNCHER_TARGET"

printf '\nInstallation complete. Running the built-in checks...\n\n'
"$LAUNCHER_TARGET" doctor

printf '\nStart the desktop with:\n\n'
printf '  budgie26 start\n\n'
printf 'Maximize it with:\n\n'
printf '  budgie26 maximize\n'

