#!/bin/sh
# Start Plik on Railway: persistent data on /data, logins forced, a first-boot
# admin from PLIKD_DEFAULT_ADMIN_PASSWORD, sensible size and expiry limits.
# Every value below is a default: set the same PLIKD_* variable on the service
# to override it (any key from plikd.cfg works, see the Plik configuration docs).
set -eu

DATA_DIR="${PLIK_DATA_DIR:-/data}"

# Railway sets PORT; plikd reads PLIKD_LISTEN_PORT.
export PLIKD_LISTEN_PORT="${PLIKD_LISTEN_PORT:-${PORT:-8080}}"
export PLIKD_LISTEN_ADDRESS="${PLIKD_LISTEN_ADDRESS:-0.0.0.0}"

# Storage: uploaded files and the SQLite metadata database both live on the volume.
export PLIKD_DATA_BACKEND="${PLIKD_DATA_BACKEND:-file}"
if [ -z "${PLIKD_DATA_BACKEND_CONFIG:-}" ]; then
  export PLIKD_DATA_BACKEND_CONFIG="{\"Directory\":\"$DATA_DIR/files\"}"
fi
if [ -z "${PLIKD_METADATA_BACKEND_CONFIG:-}" ]; then
  export PLIKD_METADATA_BACKEND_CONFIG="{\"Driver\":\"sqlite3\",\"ConnectionString\":\"$DATA_DIR/plik.db\"}"
fi

# Only signed-in users can upload; the admin account is created on first boot.
export PLIKD_FEATURE_AUTHENTICATION="${PLIKD_FEATURE_AUTHENTICATION:-forced}"
export PLIKD_DEFAULT_ADMIN_LOGIN="${PLIKD_DEFAULT_ADMIN_LOGIN:-admin}"
if [ "$PLIKD_FEATURE_AUTHENTICATION" != "disabled" ] && [ -z "${PLIKD_DEFAULT_ADMIN_PASSWORD:-}" ]; then
  echo "plik-start: PLIKD_DEFAULT_ADMIN_PASSWORD is empty; set it (the template generates one) so the admin password is known." >&2
  exit 1
fi

# Limits: 1 GB per file, uploads expire after 7 days by default and 30 days at most.
export PLIKD_MAX_FILE_SIZE_STR="${PLIKD_MAX_FILE_SIZE_STR:-1GB}"
export PLIKD_DEFAULT_TTL_STR="${PLIKD_DEFAULT_TTL_STR:-7d}"
export PLIKD_MAX_TTL_STR="${PLIKD_MAX_TTL_STR:-30d}"
# Store-only zip archives: no CPU-heavy compression on a small instance.
export PLIKD_ENABLE_ARCHIVE_COMPRESSION="${PLIKD_ENABLE_ARCHIVE_COMPRESSION:-false}"

# Railway serves every domain over HTTPS: send HSTS and Secure session cookies.
export PLIKD_ASSUME_HTTPS="${PLIKD_ASSUME_HTTPS:-true}"

# Behind Railway's proxy: log the real client address.
export PLIKD_SOURCE_IP_HEADER="${PLIKD_SOURCE_IP_HEADER:-X-Real-IP}"

# Keep the Go runtime inside the container's memory limit (cgroup v2 or v1).
if [ -z "${GOMEMLIMIT:-}" ]; then
  lim=""
  if [ -r /sys/fs/cgroup/memory.max ]; then lim=$(cat /sys/fs/cgroup/memory.max)
  elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then lim=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes); fi
  case "$lim" in
    ''|max|*[!0-9]*) ;;
    *) if [ "$lim" -lt 68719476736 ]; then export GOMEMLIMIT="$(( lim / 1048576 * 80 / 100 ))MiB"; fi ;;
  esac
fi

# The volume is mounted as root: hand it to the plik user (UID 1000) once.
mkdir -p "$DATA_DIR/files"
if [ "$(id -u)" = "0" ]; then
  if [ "$(stat -c %u "$DATA_DIR")" != "1000" ] || [ "$(stat -c %u "$DATA_DIR/files")" != "1000" ]; then
    chown -R 1000:1000 "$DATA_DIR"
  fi
  # plikd exits non-zero on any startup or serve error, so Railway's ON_FAILURE restart applies.
  exec su -p -s /bin/sh plik -c 'exec ./plikd "$@"' -- plikd "$@"
fi
exec ./plikd "$@"
