#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [--enable | --check]

  --enable  Enable native WSL systemd in /etc/wsl.conf (default)
  --check   Show the current WSL and systemd status
EOF
}

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

require_ubuntu_2604() {
    grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || die "This script must be run inside WSL."
    [[ "$(os_value ID 2>/dev/null || true)" == "ubuntu" ]] || die "This script requires Ubuntu."
    [[ "$(os_value VERSION_ID 2>/dev/null || true)" == "26.04" ]] || die "This script requires Ubuntu 26.04."
}

show_status() {
    local pid1 system_state user_state

    pid1="$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')"
    system_state="not running"
    user_state="not available"

    if [[ "$pid1" == "systemd" ]]; then
        system_state="$(systemctl is-system-running 2>/dev/null || true)"
        [[ -n "$system_state" ]] || system_state="running"
        user_state="$(systemctl --user is-system-running 2>/dev/null || true)"
        [[ -n "$user_state" ]] || user_state="not available"
    fi

    printf 'Operating system: %s\n' "$(os_value PRETTY_NAME 2>/dev/null || true)"
    printf 'WSL distribution: %s\n' "${WSL_DISTRO_NAME:-unknown}"
    printf 'Kernel: %s\n' "$(uname -r)"
    printf 'PID 1: %s\n' "${pid1:-unknown}"
    printf 'System systemd: %s\n' "$system_state"
    printf 'User systemd: %s\n' "$user_state"
    printf 'DISPLAY: %s\n' "${DISPLAY:-not set}"
    printf 'WAYLAND_DISPLAY: %s\n' "${WAYLAND_DISPLAY:-not set}"

    [[ "$pid1" == "systemd" ]]
}

enable_systemd() {
    local source_file="/dev/null"
    local temporary_file

    if [[ "$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')" == "systemd" ]]; then
        printf 'Native WSL systemd is already active.\n'
        show_status
        return 0
    fi

    [[ -f /etc/wsl.conf ]] && source_file="/etc/wsl.conf"
    temporary_file="$(mktemp)"
    trap 'rm -f "${temporary_file:-}"' EXIT

    awk '
        BEGIN { in_boot = 0; boot_seen = 0; systemd_seen = 0 }
        /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
            if (in_boot && !systemd_seen) print "systemd=true"
            in_boot = ($0 ~ /^[[:space:]]*\[boot\][[:space:]]*$/)
            if (in_boot) { boot_seen = 1; systemd_seen = 0 }
            print
            next
        }
        {
            if (in_boot && $0 ~ /^[[:space:]]*systemd[[:space:]]*=/) {
                if (!systemd_seen) { print "systemd=true"; systemd_seen = 1 }
                next
            }
            print
        }
        END {
            if (in_boot && !systemd_seen) print "systemd=true"
            if (!boot_seen) {
                if (NR > 0) print ""
                print "[boot]"
                print "systemd=true"
            }
        }
    ' "$source_file" > "$temporary_file"

    sudo install -o root -g root -m 0644 "$temporary_file" /etc/wsl.conf
    printf 'Native WSL systemd has been enabled in /etc/wsl.conf.\n'
}

main() {
    require_ubuntu_2604

    case "${1:---enable}" in
        --enable)
            enable_systemd
            ;;
        --check)
            show_status
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"

