#!/bin/bash
# AnythingLLM start (Railway). Runs as root, prepares the volume, then runs the
# image's own entrypoint as the unprivileged anythingllm user.
#
# - Settings chosen in the UI (LLM provider, model, keys) live in
#   /app/server/.env. Upstream keeps that file outside the data directory, so a
#   redeploy would forget them; here it is a symlink to $STORAGE_DIR/.env.
# - No deploy-form value stops the deploy (STANDARD 8.29): a missing or too
#   short password locks the instance with a random one instead of opening it.
set -u

log() { echo "[railway-start] $*"; }
warn() { echo "[railway-start] WARNING: $*" >&2; }
random_token() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

APP_UID=1000
APP_GID=1000

# Railway may pass optional variables as empty strings. dotenv never replaces a
# variable that exists, so an empty OPEN_AI_KEY would hide the key saved in the
# UI. Drop every empty variable before the app starts.
for name in $(compgen -e); do
	[ -z "${!name}" ] && unset "$name"
done

storage=${STORAGE_DIR:-/app/server/storage}
case "$storage" in
/*) ;;
*) warn "STORAGE_DIR='$storage' is not an absolute path; using /app/server/storage"; storage=/app/server/storage ;;
esac
export STORAGE_DIR=$storage
if [ "$storage" != /app/server/storage ]; then
	# The server finds the collector's upload folder at $STORAGE_DIR/../../collector/hotdir.
	warn "STORAGE_DIR=$storage: document uploads only work with /app/server/storage (upstream's layout)"
fi

port=${SERVER_PORT:-${PORT:-3001}}
case "$port" in
'' | *[!0-9]*) warn "SERVER_PORT='$port' is not a port number; using 3001"; port=3001 ;;
esac
export SERVER_PORT=$port

if [ -n "${PORT:-}" ] && [ "${PORT}" != "$port" ]; then
	warn "PORT=${PORT} differs from SERVER_PORT=$port; Railway's healthcheck uses PORT, so set both to the same value"
fi

mkdir -p "$storage"
if ! mountpoint -q "$storage" 2>/dev/null; then
	warn "$storage is not a mounted volume: documents, chats and settings are lost on every redeploy"
fi

# Volumes from templates that ran the app as root need their files handed over.
if [ -n "$(find "$storage" -maxdepth 3 ! -user "$APP_UID" -print -quit 2>/dev/null)" ]; then
	log "giving $storage to uid $APP_UID"
	chown -R "$APP_UID:$APP_GID" "$storage"
fi

# Persist the settings file on the volume.
env_file="$storage/.env"
if [ ! -f "$env_file" ]; then
	printf '# AnythingLLM settings saved from the UI (kept on the Railway volume)\n' >"$env_file"
fi
chown "$APP_UID:$APP_GID" "$env_file"
chmod 0600 "$env_file"
ln -sfn "$env_file" /app/server/.env

# Single-user password mode needs AUTH_TOKEN and JWT_SECRET; without either one
# AnythingLLM serves everything without a sign-in.
password=${AUTH_TOKEN:-}
if [ "${#password}" -lt 8 ] || [ "${#password}" -gt 128 ] || ! [[ "$password" =~ ^[A-Za-z0-9_!@\$%^\&*\(\)\;-]+$ ]]; then
	warn "AUTH_TOKEN is empty, shorter than 8 or longer than 128 characters, or has characters"
	warn "outside A-Z a-z 0-9 _ - ! @ \$ % ^ & * ( ) ;. The instance is LOCKED with a random"
	warn "password nobody knows. Set AUTH_TOKEN on the AnythingLLM service and redeploy to sign in."
	password=$(random_token)
fi
export AUTH_TOKEN=$password
unset password

secret_file() {
	# Keep a generated value on the volume so sessions and encrypted data survive restarts.
	local file="$storage/.railway-$1"
	if [ ! -s "$file" ]; then
		random_token >"$file"
		chown "$APP_UID:$APP_GID" "$file"
		chmod 0600 "$file"
	fi
	cat "$file"
}
jwt=${JWT_SECRET:-}
if [ "${#jwt}" -lt 12 ]; then
	warn "JWT_SECRET is missing or shorter than 12 characters; using one stored on the volume"
	jwt=$(secret_file jwt-secret)
fi
export JWT_SECRET=$jwt
unset jwt

for key in SIG_KEY SIG_SALT; do
	if [ -z "${!key:-}" ] && ! grep -q "^$key=" "$env_file"; then
		warn "$key is not set; AnythingLLM generates one and saves it in $env_file"
	fi
done

limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
case "$limit" in
'' | max | *[!0-9]*) ;;
*) [ "$limit" -ge 805306368 ] || warn "memory limit is $((limit / 1048576)) MiB; AnythingLLM needs about 0.8 GB with the built-in embedder" ;;
esac

log "AnythingLLM 1.20.0, storage $storage, port $SERVER_PORT, password mode on"
cd /app || exit 1
exec setpriv --reuid="$APP_UID" --regid="$APP_GID" --init-groups \
	env HOME=/app USER=anythingllm \
	/bin/bash /usr/local/bin/docker-entrypoint.sh "$@"
