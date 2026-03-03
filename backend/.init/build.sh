#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/code-generation/react-todo-list-237620-237634/backend"
cd "$WORKSPACE"
export NODE_ENV=production
# Run build; return specific exit codes for failures
npm run build --silent || { echo "Build failed" >&2; exit 50; }
# record bundle type if bundler config exists
# keep this lightweight: prefer .bundle-type written earlier in pipeline; no-op if missing
