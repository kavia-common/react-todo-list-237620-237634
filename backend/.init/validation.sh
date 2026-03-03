#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/code-generation/react-todo-list-237620-237634/backend"
cd "$WORKSPACE"
# Build
export NODE_ENV=production
npm run build --silent || { echo "Build failed" >&2; exit 50; }
# Determine output dir
BUNDLER=$(cat .bundle-type 2>/dev/null || echo cra)
if [ "$BUNDLER" = "vite" ]; then OUT=dist; else OUT=build; fi
[ -d "$OUT" ] || { echo "Build output directory '$OUT' not found" >&2; ls -la || true; exit 51; }
# Start server
SERVE_BIN="$WORKSPACE/node_modules/.bin/serve"
PORT=5000
if [ -x "$SERVE_BIN" ]; then CMD=("$SERVE_BIN" -s "$OUT" -l "$PORT"); else CMD=(python3 -m http.server "$PORT" --directory "$OUT"); fi
LOG=/tmp/validation_serve.log
setsid "${CMD[@]}" >"${LOG}" 2>&1 &
PID=$!
sleep 0.1
PGID=$(ps -o pgid= $PID | tr -d ' ')
trap 'kill -TERM -$PGID 2>/dev/null || true; wait $PID 2>/dev/null || true; rm -f ${LOG} /tmp/validation_serve.pid /tmp/validation_serve.pgid' EXIT
# Save for potential external stop
echo "$PID" > /tmp/validation_serve.pid
echo "$PGID" > /tmp/validation_serve.pgid
# Health check
MAX_WAIT=30
COUNT=0
HTTP=000
until [ ${COUNT} -ge ${MAX_WAIT} ]; do
  if ! kill -0 ${PID} >/dev/null 2>&1; then echo "Serve process died" >&2; tail -n 200 ${LOG} || true; exit 52; fi
  for host in 127.0.0.1 localhost; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://$host:${PORT} || echo "000")
    if [ "$HTTP" = "200" ] || [ "$HTTP" = "301" ] || [ "$HTTP" = "302" ]; then break 2; fi
  done
  COUNT=$((COUNT+1))
  sleep 1
done
if [ "$HTTP" != "200" ] && [ "$HTTP" != "301" ] && [ "$HTTP" != "302" ]; then echo "Health check failed (HTTP=${HTTP})" >&2; tail -n 200 ${LOG} || true; exit 53; fi
# Evidence
du -sh "$OUT" || true
tail -n 200 ${LOG} || true
# Cleanup
kill -TERM -$PGID 2>/dev/null || true
wait $PID 2>/dev/null || true
trap - EXIT
