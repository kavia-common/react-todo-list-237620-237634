#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/code-generation/react-todo-list-237620-237634/backend"
cd "$WORKSPACE"
# Run jest if present, otherwise no-op
if [ -x "./node_modules/.bin/jest" ]; then CI=true ./node_modules/.bin/jest --runInBand --silent || { echo "Tests failed" >&2; exit 60; }; else
  if npm run | grep -q " test"; then CI=true npm test --silent || { echo "Tests failed via npm test" >&2; exit 60; }; else
    # no tests configured; treat as success
    exit 0
  fi
fi
