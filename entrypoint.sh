#!/usr/bin/env bash
set -euo pipefail

secret_file=/run/secrets/rdp_password
if [[ ! -r "$secret_file" ]]; then
  echo 'ERROR: Required Docker secret /run/secrets/rdp_password is missing.' >&2
  exit 1
fi
password="$(cat "$secret_file")"
if (( ${#password} < 12 )) || [[ "$password" == *$'\n'* ]] || [[ "$password" == *:* ]]; then
  echo 'ERROR: RDP password needs >=12 characters without a newline or colon.' >&2
  exit 1
fi
printf 'developer:%s\n' "$password" | chpasswd
unset password

if [[ -S /var/run/docker.sock ]]; then
  sock_gid="$(stat -c '%g' /var/run/docker.sock)"
  groupadd -for -g "$sock_gid" docker-host
  usermod -aG docker-host developer
fi

mkdir -p /run/dbus /run/xrdp /var/run/xrdp
# This container intentionally does not run systemd.
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/xrdp-workstation.conf

