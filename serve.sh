#!/usr/bin/env bash
# serve.sh — single server, the faithful replacement for the old Docker CMD:
#   CMD ["run-llama-server", "--host", "0.0.0.0", "--port", "8080"]
# run-llama-server sets LD_LIBRARY_PATH=$APP_DIR/lib then execs llama-server,
# so the bundled CUDA libs are used regardless of the pod's base image.
set -euo pipefail
APP_DIR="${APP_DIR:-/app}"
exec "$APP_DIR/bin/run-llama-server" --host 0.0.0.0 --port "${PORT:-8080}" "$@"
