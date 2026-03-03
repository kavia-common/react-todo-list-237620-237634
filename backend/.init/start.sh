#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/code-generation/react-todo-list-237620-237634/backend"
cd "$WORKSPACE"
# Determine bundle output
BUNDLER=$(cat .bundle-type 2>/dev/null || echo cra)
if [ "$BUNDLER" = "vite" ]; then OUT=dist; else OUT=build; fi
[ -d "$OUT" ] || { echo "Build output directory '$OUT' not found" >&2; ls -la || true; exit 51; }
SERVE_BIN="$WORKSPACE/node_modules/.bin/serve"
PORT=5000
# choose command
if [ -x "$SERVE_BIN" ]; then CMD=("$SERVE_BIN" -s "$OUT" -l "$PORT"); else CMD=(python3 -m http.server "$PORT" --directory "$OUT"); fi
LOG=/tmp/validation_serve.log
# start in new session so we can kill process group
setsid "${CMD[@]}" >"${LOG}" 2>&1 &
PID=$!
# capture PGID
sleep 0.1
PGID=$(ps -o pgid= $PID | tr -d ' ')
if [ -z "$PGID" ]; then echo "Failed to determine PGID" >&2; exit 52; fi
# output PID file for stop script
echo "$PID" > /tmp/validation_serve.pid
echo "$PGID" > /tmp/validation_serve.pgid
# wait briefly to let server initialize
